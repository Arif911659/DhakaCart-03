const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const redis = require('redis');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL Connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'dhakacart',
  password: process.env.DB_PASSWORD || 'dhakacart123',
  database: process.env.DB_NAME || 'dhakacart_db',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Redis Connection
const redisClient = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
  },
});

redisClient.on('error', (err) => console.log('Redis Client Error', err));
redisClient.connect();

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date() });
});

// Get all products with caching
app.get('/api/products', async (req, res) => {
  try {
    // Check Redis cache first
    const cachedProducts = await redisClient.get('products:all');
    
    if (cachedProducts) {
      console.log('✅ Serving from Redis cache');
      return res.json({ source: 'cache', data: JSON.parse(cachedProducts) });
    }

    // If not in cache, fetch from database
    const result = await pool.query('SELECT * FROM products ORDER BY id');
    
    // Convert numeric strings to actual numbers
    const products = result.rows.map(product => ({
      ...product,
      price: parseFloat(product.price),
      stock: parseInt(product.stock)
    }));
    
    // Store in Redis cache for 5 minutes
    await redisClient.setEx('products:all', 300, JSON.stringify(products));
    
    console.log('✅ Serving from Database');
    res.json({ source: 'database', data: products });
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

// Get product by ID
app.get('/api/products/:id', async (req, res) => {
  const { id } = req.params;
  
  try {
    const cacheKey = `product:${id}`;
    const cachedProduct = await redisClient.get(cacheKey);
    
    if (cachedProduct) {
      return res.json({ source: 'cache', data: JSON.parse(cachedProduct) });
    }

    const result = await pool.query('SELECT * FROM products WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    const product = {
      ...result.rows[0],
      price: parseFloat(result.rows[0].price),
      stock: parseInt(result.rows[0].stock)
    };

    await redisClient.setEx(cacheKey, 300, JSON.stringify(product));
    res.json({ source: 'database', data: product });
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({ error: 'Failed to fetch product' });
  }
});

// Get products by category
app.get('/api/products/category/:category', async (req, res) => {
  const { category } = req.params;
  
  try {
    const result = await pool.query(
      'SELECT * FROM products WHERE category = $1 ORDER BY name',
      [category]
    );
    
    const products = result.rows.map(product => ({
      ...product,
      price: parseFloat(product.price),
      stock: parseInt(product.stock)
    }));
    
    res.json({ data: products });
  } catch (error) {
    console.error('Error fetching products by category:', error);
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

// Create new order
app.post('/api/orders', async (req, res) => {
  const { customer_name, customer_email, customer_phone, delivery_address, items, total_amount } = req.body;

  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // Insert order
    const orderResult = await client.query(
      `INSERT INTO orders (customer_name, customer_email, customer_phone, delivery_address, total_amount, status)
       VALUES ($1, $2, $3, $4, $5, 'pending') RETURNING *`,
      [customer_name, customer_email, customer_phone, delivery_address, total_amount]
    );

    const orderId = orderResult.rows[0].id;

    // Insert order items
    for (const item of items) {
      await client.query(
        `INSERT INTO order_items (order_id, product_id, quantity, price)
         VALUES ($1, $2, $3, $4)`,
        [orderId, item.product_id, item.quantity, item.price]
      );

      // Update product stock
      await client.query(
        'UPDATE products SET stock = stock - $1 WHERE id = $2',
        [item.quantity, item.product_id]
      );
    }

    await client.query('COMMIT');

    // Invalidate products cache
    await redisClient.del('products:all');

    // Convert total_amount to number before sending
    const orderResponse = {
      ...orderResult.rows[0],
      total_amount: parseFloat(orderResult.rows[0].total_amount)
    };

    res.status(201).json({
      message: 'Order placed successfully',
      order: orderResponse,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating order:', error);
    res.status(500).json({ error: 'Failed to create order' });
  } finally {
    client.release();
  }
});

// Get order by ID
app.get('/api/orders/:id', async (req, res) => {
  const { id } = req.params;
  
  try {
    const orderResult = await pool.query('SELECT * FROM orders WHERE id = $1', [id]);
    
    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const itemsResult = await pool.query(
      `SELECT oi.*, p.name, p.image_url
       FROM order_items oi
       JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = $1`,
      [id]
    );

    res.json({
      order: orderResult.rows[0],
      items: itemsResult.rows,
    });
  } catch (error) {
    console.error('Error fetching order:', error);
    res.status(500).json({ error: 'Failed to fetch order' });
  }
});

// Get all categories
app.get('/api/categories', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT DISTINCT category FROM products ORDER BY category'
    );
    res.json({ data: result.rows.map(row => row.category) });
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

// Clear cache (admin endpoint)
app.post('/api/admin/clear-cache', async (req, res) => {
  try {
    await redisClient.flushAll();
    res.json({ message: 'Cache cleared successfully' });
  } catch (error) {
    console.error('Error clearing cache:', error);
    res.status(500).json({ error: 'Failed to clear cache' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 DhakaCart Backend running on port ${PORT}`);
  console.log(`📊 Database: ${process.env.DB_HOST}:${process.env.DB_PORT}`);
  console.log(`🔴 Redis: ${process.env.REDIS_HOST}:${process.env.REDIS_PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing connections...');
  await pool.end();
  await redisClient.quit();
  process.exit(0);
});