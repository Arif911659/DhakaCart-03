import React, { useState, useEffect } from 'react';
import './App.css';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

function App() {
  const [products, setProducts] = useState([]);
  const [cart, setCart] = useState([]);
  const [loading, setLoading] = useState(true);
  const [categories, setCategories] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [showCart, setShowCart] = useState(false);
  const [showCheckout, setShowCheckout] = useState(false);
  const [orderSuccess, setOrderSuccess] = useState(null);

  // Checkout form state
  const [customerInfo, setCustomerInfo] = useState({
    name: '',
    email: '',
    phone: '',
    address: ''
  });

  // Load products and categories
  useEffect(() => {
    fetchProducts();
    fetchCategories();
  }, []);

  const fetchProducts = async () => {
    try {
      const response = await fetch(`${API_URL}/products`);
      const data = await response.json();
      // Convert price strings to numbers
      const productsWithNumbers = (data.data || []).map(product => ({
        ...product,
        price: parseFloat(product.price),
        stock: parseInt(product.stock)
      }));
      setProducts(productsWithNumbers);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching products:', error);
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const response = await fetch(`${API_URL}/categories`);
      const data = await response.json();
      setCategories(['All', ...(data.data || [])]);
    } catch (error) {
      console.error('Error fetching categories:', error);
    }
  };

  const addToCart = (product) => {
    const existingItem = cart.find(item => item.id === product.id);
    
    if (existingItem) {
      setCart(cart.map(item =>
        item.id === product.id
          ? { ...item, quantity: item.quantity + 1 }
          : item
      ));
    } else {
      setCart([...cart, { 
        ...product, 
        quantity: 1,
        price: parseFloat(product.price) // Ensure price is number
      }]);
    }
  };

  const removeFromCart = (productId) => {
    setCart(cart.filter(item => item.id !== productId));
  };

  const updateQuantity = (productId, newQuantity) => {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }
    setCart(cart.map(item =>
      item.id === productId ? { ...item, quantity: newQuantity } : item
    ));
  };

  const getTotalAmount = () => {
    return cart.reduce((total, item) => total + (item.price * item.quantity), 0);
  };

  const handleCheckout = async (e) => {
    e.preventDefault();
    
    if (cart.length === 0) {
      alert('আপনার কার্ট খালি!');
      return;
    }

    try {
      const orderData = {
        customer_name: customerInfo.name,
        customer_email: customerInfo.email,
        customer_phone: customerInfo.phone,
        delivery_address: customerInfo.address,
        total_amount: getTotalAmount(),
        items: cart.map(item => ({
          product_id: item.id,
          quantity: item.quantity,
          price: item.price
        }))
      };

      const response = await fetch(`${API_URL}/orders`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orderData)
      });

      const result = await response.json();
      
      if (response.ok) {
        setOrderSuccess(result.order);
        setCart([]);
        setShowCheckout(false);
        setCustomerInfo({ name: '', email: '', phone: '', address: '' });
        fetchProducts(); // Refresh products to update stock
      } else {
        alert('অর্ডার করতে সমস্যা হয়েছে!');
      }
    } catch (error) {
      console.error('Error placing order:', error);
      alert('অর্ডার করতে সমস্যা হয়েছে!');
    }
  };

  const filteredProducts = selectedCategory === 'All'
    ? products
    : products.filter(p => p.category === selectedCategory);

  if (loading) {
    return (
      <div className="loading-screen">
        <div className="spinner"></div>
        <p>লোড হচ্ছে...</p>
      </div>
    );
  }

  return (
    <div className="App">
      {/* Header */}
      <header className="header">
        <div className="container">
          <h1>🛒 DhakaCart</h1>
          <p className="tagline">বাংলাদেশের অনলাইন শপিং</p>
          <button className="cart-button" onClick={() => setShowCart(!showCart)}>
            🛒 কার্ট ({cart.length})
            {cart.length > 0 && (
              <span className="cart-badge">{cart.reduce((sum, item) => sum + item.quantity, 0)}</span>
            )}
          </button>
        </div>
      </header>

      {/* Order Success Message */}
      {orderSuccess && (
        <div className="success-banner">
          <div className="container">
            <h3>✅ অর্ডার সফল হয়েছে!</h3>
            <p>অর্ডার নম্বর: #{orderSuccess.id}</p>
            <p>মোট: ৳{orderSuccess.total_amount.toFixed(2)}</p>
            <button onClick={() => setOrderSuccess(null)}>বন্ধ করুন</button>
          </div>
        </div>
      )}

      {/* Categories Filter */}
      <div className="categories">
        <div className="container">
          {categories.map(category => (
            <button
              key={category}
              className={`category-btn ${selectedCategory === category ? 'active' : ''}`}
              onClick={() => setSelectedCategory(category)}
            >
              {category}
            </button>
          ))}
        </div>
      </div>

      {/* Main Content */}
      <main className="container">
        {/* Cart Sidebar */}
        {showCart && (
          <div className="cart-sidebar">
            <div className="cart-header">
              <h2>🛒 আপনার কার্ট</h2>
              <button onClick={() => setShowCart(false)}>✕</button>
            </div>
            
            {cart.length === 0 ? (
              <p className="empty-cart">কার্ট খালি</p>
            ) : (
              <>
                <div className="cart-items">
                  {cart.map(item => (
                    <div key={item.id} className="cart-item">
                      <img src={item.image_url} alt={item.name} />
                      <div className="cart-item-info">
                        <h4>{item.name}</h4>
                        <p>৳{item.price.toFixed(2)}</p>
                        <div className="quantity-controls">
                          <button onClick={() => updateQuantity(item.id, item.quantity - 1)}>-</button>
                          <span>{item.quantity}</span>
                          <button onClick={() => updateQuantity(item.id, item.quantity + 1)}>+</button>
                        </div>
                      </div>
                      <button className="remove-btn" onClick={() => removeFromCart(item.id)}>🗑️</button>
                    </div>
                  ))}
                </div>
                
                <div className="cart-footer">
                  <div className="cart-total">
                    <strong>মোট:</strong>
                    <strong>৳{getTotalAmount().toFixed(2)}</strong>
                  </div>
                  <button className="checkout-btn" onClick={() => setShowCheckout(true)}>
                    চেকআউট করুন
                  </button>
                </div>
              </>
            )}
          </div>
        )}

        {/* Checkout Modal */}
        {showCheckout && (
          <div className="modal-overlay" onClick={() => setShowCheckout(false)}>
            <div className="modal" onClick={(e) => e.stopPropagation()}>
              <h2>চেকআউট</h2>
              <form onSubmit={handleCheckout}>
                <input
                  type="text"
                  placeholder="আপনার নাম"
                  value={customerInfo.name}
                  onChange={(e) => setCustomerInfo({...customerInfo, name: e.target.value})}
                  required
                />
                <input
                  type="email"
                  placeholder="ইমেইল"
                  value={customerInfo.email}
                  onChange={(e) => setCustomerInfo({...customerInfo, email: e.target.value})}
                  required
                />
                <input
                  type="tel"
                  placeholder="ফোন নম্বর"
                  value={customerInfo.phone}
                  onChange={(e) => setCustomerInfo({...customerInfo, phone: e.target.value})}
                  required
                />
                <textarea
                  placeholder="ডেলিভারি ঠিকানা"
                  value={customerInfo.address}
                  onChange={(e) => setCustomerInfo({...customerInfo, address: e.target.value})}
                  required
                  rows="3"
                />
                
                <div className="order-summary">
                  <h3>অর্ডার সামারি:</h3>
                  {cart.map(item => (
                    <div key={item.id} className="summary-item">
                      <span>{item.name} (x{item.quantity})</span>
                      <span>৳{(item.price * item.quantity).toFixed(2)}</span>
                    </div>
                  ))}
                  <div className="summary-total">
                    <strong>মোট:</strong>
                    <strong>৳{getTotalAmount().toFixed(2)}</strong>
                  </div>
                </div>

                <div className="modal-actions">
                  <button type="button" onClick={() => setShowCheckout(false)}>বাতিল</button>
                  <button type="submit" className="submit-btn">অর্ডার নিশ্চিত করুন</button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Products Grid */}
        <div className="products-grid">
          {filteredProducts.map(product => (
            <div key={product.id} className="product-card">
              <img src={product.image_url} alt={product.name} />
              <div className="product-info">
                <h3>{product.name}</h3>
                <p className="product-description">{product.description}</p>
                <div className="product-footer">
                  <span className="price">৳{product.price.toFixed(2)}</span>
                  <span className="stock">স্টক: {product.stock}</span>
                </div>
                <button
                  className="add-to-cart-btn"
                  onClick={() => addToCart(product)}
                  disabled={product.stock === 0}
                >
                  {product.stock > 0 ? 'কার্টে যোগ করুন' : 'স্টক নেই'}
                </button>
              </div>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer className="footer">
        <div className="container">
          <p>© 2024 DhakaCart - Made with ❤️ in Bangladesh</p>
        </div>
      </footer>
    </div>
  );
}

export default App;