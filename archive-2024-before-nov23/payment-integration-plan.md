# DhakaCart Payment Integration Plan
**Date:** 2025-11-22  
**Addition to DevOps Transformation Plan**

---

## Why Payment Integration is Critical

The project mentions:
> "No HTTPS — all user and payment data travel in plain text" (Line 34)

This implies DhakaCart **processes payments**. For a Bangladeshi e-commerce platform, you need:

1. **bKash** - Most popular mobile payment in Bangladesh
2. **Nagad** - Second largest mobile financial service
3. **SSL Commerz** - Gateway supporting cards, mobile banking, internet banking
4. **Cash on Delivery (COD)** - Still popular in Bangladesh

---

## Phase 8: Payment Gateway Integration (NEW - HIGH Priority)

### 8.1 Payment Architecture Design

#### Backend Changes Needed:

```
backend/
├── controllers/
│   └── paymentController.js      # Payment logic
├── services/
│   ├── bkashService.js           # bKash API integration
│   ├── nagadService.js           # Nagad API integration
│   └── sslcommerzService.js      # SSL Commerz integration
├── models/
│   ├── Payment.js                # Payment records
│   └── Transaction.js            # Transaction logs
└── routes/
    └── paymentRoutes.js          # Payment endpoints
```

#### Database Schema:

```sql
-- Add to init.sql

CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    payment_method VARCHAR(50) NOT NULL, -- 'bkash', 'nagad', 'sslcommerz', 'cod'
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'success', 'failed', 'refunded'
    transaction_id VARCHAR(255),
    gateway_response JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_transaction_id ON payments(transaction_id);
```

---

### 8.2 bKash Integration (Recommended for Bangladesh)

#### Steps:

1. **Register for bKash Merchant Account:**
   - Go to: https://www.bkash.com/en/business
   - Apply for merchant account (takes 5-7 days)
   - Get API credentials: `username`, `password`, `app_key`, `app_secret`

2. **Install bKash SDK:**
```bash
cd backend
npm install axios  # For API calls
```

3. **Create bKash Service:**

```javascript
// backend/services/bkashService.js

const axios = require('axios');

class BkashService {
  constructor() {
    this.baseURL = process.env.BKASH_BASE_URL || 'https://tokenized.sandbox.bka.sh/v1.2.0-beta';
    this.username = process.env.BKASH_USERNAME;
    this.password = process.env.BKASH_PASSWORD;
    this.app_key = process.env.BKASH_APP_KEY;
    this.app_secret = process.env.BKASH_APP_SECRET;
    this.token = null;
  }

  // Get auth token
  async getToken() {
    try {
      const response = await axios.post(`${this.baseURL}/tokenized/checkout/token/grant`, {
        app_key: this.app_key,
        app_secret: this.app_secret
      }, {
        headers: {
          'username': this.username,
          'password': this.password
        }
      });
      
      this.token = response.data.id_token;
      return this.token;
    } catch (error) {
      console.error('bKash token error:', error);
      throw error;
    }
  }

  // Create payment
  async createPayment(amount, orderId, customerPhone) {
    if (!this.token) await this.getToken();
    
    try {
      const response = await axios.post(`${this.baseURL}/tokenized/checkout/create`, {
        mode: '0011',
        payerReference: customerPhone,
        callbackURL: `${process.env.APP_URL}/api/payments/bkash/callback`,
        amount: amount.toString(),
        currency: 'BDT',
        intent: 'sale',
        merchantInvoiceNumber: `INV-${orderId}`
      }, {
        headers: {
          'Authorization': this.token,
          'X-APP-Key': this.app_key
        }
      });
      
      return response.data;
    } catch (error) {
      console.error('bKash payment creation error:', error);
      throw error;
    }
  }

  // Execute payment
  async executePayment(paymentID) {
    if (!this.token) await this.getToken();
    
    try {
      const response = await axios.post(`${this.baseURL}/tokenized/checkout/execute`, {
        paymentID
      }, {
        headers: {
          'Authorization': this.token,
          'X-APP-Key': this.app_key
        }
      });
      
      return response.data;
    } catch (error) {
      console.error('bKash payment execution error:', error);
      throw error;
    }
  }

  // Query payment status
  async queryPayment(paymentID) {
    if (!this.token) await this.getToken();
    
    try {
      const response = await axios.post(`${this.baseURL}/tokenized/checkout/payment/status`, {
        paymentID
      }, {
        headers: {
          'Authorization': this.token,
          'X-APP-Key': this.app_key
        }
      });
      
      return response.data;
    } catch (error) {
      console.error('bKash query error:', error);
      throw error;
    }
  }
}

module.exports = new BkashService();
```

4. **Add Payment Controller:**

```javascript
// backend/controllers/paymentController.js

const bkashService = require('../services/bkashService');
const { Pool } = require('pg');

const pool = new Pool({ /* your DB config */ });

// Initiate bKash payment
exports.initiateBkashPayment = async (req, res) => {
  const { orderId, amount, customerPhone } = req.body;
  
  try {
    const payment = await bkashService.createPayment(amount, orderId, customerPhone);
    
    // Save payment record
    await pool.query(
      `INSERT INTO payments (order_id, payment_method, amount, status, transaction_id, gateway_response)
       VALUES ($1, 'bkash', $2, 'pending', $3, $4)`,
      [orderId, amount, payment.paymentID, JSON.stringify(payment)]
    );
    
    res.json({
      success: true,
      bkashURL: payment.bkashURL,  // Redirect user here
      paymentID: payment.paymentID
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Handle bKash callback
exports.bkashCallback = async (req, res) => {
  const { paymentID, status } = req.query;
  
  try {
    if (status === 'success') {
      const result = await bkashService.executePayment(paymentID);
      
      // Update payment status
      await pool.query(
        `UPDATE payments SET status = 'success', gateway_response = $1, updated_at = NOW()
         WHERE transaction_id = $2`,
        [JSON.stringify(result), paymentID]
      );
      
      // Update order status
      const payment = await pool.query('SELECT order_id FROM payments WHERE transaction_id = $1', [paymentID]);
      await pool.query(
        `UPDATE orders SET status = 'paid' WHERE id = $1`,
        [payment.rows[0].order_id]
      );
      
      res.redirect(`${process.env.FRONTEND_URL}/order-success?orderId=${payment.rows[0].order_id}`);
    } else {
      // Payment failed or cancelled
      await pool.query(
        `UPDATE payments SET status = 'failed', updated_at = NOW()
         WHERE transaction_id = $1`,
        [paymentID]
      );
      
      res.redirect(`${process.env.FRONTEND_URL}/payment-failed`);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Query payment status (webhook)
exports.webhookBkash = async (req, res) => {
  const { paymentID } = req.body;
  
  try {
    const status = await bkashService.queryPayment(paymentID);
    
    await pool.query(
      `UPDATE payments SET status = $1, gateway_response = $2, updated_at = NOW()
       WHERE transaction_id = $3`,
      [status.transactionStatus.toLowerCase(), JSON.stringify(status), paymentID]
    );
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
```

5. **Add Routes:**

```javascript
// backend/routes/paymentRoutes.js

const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');

// Initiate payment
router.post('/bkash/initiate', paymentController.initiateBkashPayment);

// Callback from bKash
router.get('/bkash/callback', paymentController.bkashCallback);

// Webhook from bKash
router.post('/bkash/webhook', paymentController.webhookBkash);

module.exports = router;
```

6. **Update server.js:**

```javascript
// Add to backend/server.js

const paymentRoutes = require('./routes/paymentRoutes');
app.use('/api/payments', paymentRoutes);
```

---

### 8.3 Frontend Changes

#### Update CheckoutModal Component:

```javascript
// frontend/src/components/CheckoutModal.js

// Add payment method selection
const [paymentMethod, setPaymentMethod] = useState('cod');

// In the form:
<div className="payment-methods">
  <h3>পেমেন্ট পদ্ধতি</h3>
  
  <label>
    <input 
      type="radio" 
      value="bkash" 
      checked={paymentMethod === 'bkash'}
      onChange={(e) => setPaymentMethod(e.target.value)}
    />
    <img src="/bkash-logo.png" alt="bKash" /> bKash
  </label>
  
  <label>
    <input 
      type="radio" 
      value="nagad" 
      checked={paymentMethod === 'nagad'}
      onChange={(e) => setPaymentMethod(e.target.value)}
    />
    <img src="/nagad-logo.png" alt="Nagad" /> Nagad
  </label>
  
  <label>
    <input 
      type="radio" 
      value="cod" 
      checked={paymentMethod === 'cod'}
      onChange={(e) => setPaymentMethod(e.target.value)}
    />
    💵 ক্যাশ অন ডেলিভারি
  </label>
</div>
```

#### Handle Payment Submission:

```javascript
const handlePayment = async (orderResponse) => {
  if (paymentMethod === 'cod') {
    // No payment gateway needed
    setOrderSuccess(orderResponse.order);
    return;
  }
  
  if (paymentMethod === 'bkash') {
    try {
      const response = await fetch(`${API_URL}/payments/bkash/initiate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          orderId: orderResponse.order.id,
          amount: orderResponse.order.total_amount,
          customerPhone: customerInfo.phone
        })
      });
      
      const data = await response.json();
      
      if (data.success) {
        // Redirect to bKash payment page
        window.location.href = data.bkashURL;
      } else {
        alert('পেমেন্ট শুরু করতে সমস্যা হয়েছে!');
      }
    } catch (error) {
      console.error('Payment error:', error);
      alert('পেমেন্ট শুরু করতে সমস্যা হয়েছে!');
    }
  }
};
```

---

### 8.4 Environment Variables

Add to `.env`:

```bash
# bKash Configuration
BKASH_BASE_URL=https://tokenized.sandbox.bka.sh/v1.2.0-beta
BKASH_USERNAME=your_username
BKASH_PASSWORD=your_password
BKASH_APP_KEY=your_app_key
BKASH_APP_SECRET=your_app_secret

# App URL for callbacks
APP_URL=http://localhost:5000
FRONTEND_URL=http://localhost:3000
```

For production, use:
```bash
BKASH_BASE_URL=https://tokenized.pay.bka.sh/v1.2.0-beta
```

---

### 8.5 SSL Commerz Integration (Alternative/Additional)

SSL Commerz supports multiple payment methods in one integration:
- bKash
- Nagad
- Credit/Debit Cards
- Mobile Banking (Rocket, Upay)
- Internet Banking

**Advantages:**
- Single integration for multiple payment methods
- Easier compliance (PCI-DSS certified)
- Better for cards

**Steps:**
1. Register at: https://sslcommerz.com/
2. Get Store ID and Store Password
3. Use their Node.js SDK

```bash
npm install sslcommerz-nodejs
```

---

## Security Considerations for Payments

### 1. **PCI-DSS Compliance**
- Never store card details
- Use tokenization
- SSL/TLS for all payment pages

### 2. **Webhook Security**
```javascript
// Verify webhook signatures
const crypto = require('crypto');

function verifyBkashWebhook(payload, signature) {
  const hash = crypto
    .createHmac('sha256', process.env.BKASH_APP_SECRET)
    .update(JSON.stringify(payload))
    .digest('hex');
  
  return hash === signature;
}
```

### 3. **Rate Limiting**
```javascript
// Prevent payment spam
const rateLimit = require('express-rate-limit');

const paymentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5 // max 5 payment attempts
});

app.use('/api/payments', paymentLimiter);
```

### 4. **Logging**
```javascript
// Log all payment attempts
await pool.query(
  `INSERT INTO payment_logs (order_id, action, request, response, ip_address)
   VALUES ($1, $2, $3, $4, $5)`,
  [orderId, 'initiate', JSON.stringify(req.body), JSON.stringify(response), req.ip]
);
```

---

## Testing Payment Integration

### Sandbox Credentials (bKash):

```
Merchant Wallet: 01770618575
OTP: 123456
PIN: 12345
```

### Test Cases:

1. **Successful Payment**
   - Create order
   - Initiate bKash payment
   - Complete payment in sandbox
   - Verify order status updated

2. **Failed Payment**
   - Create order
   - Initiate payment
   - Cancel in bKash
   - Verify order remains pending

3. **Timeout Handling**
   - Create order
   - Initiate payment
   - Don't complete
   - Check status after 15 minutes

---

## Implementation Timeline

| Task | Duration | Priority |
|------|----------|----------|
| Database schema for payments | 2 hours | HIGH |
| bKash service integration | 1 day | HIGH |
| Payment controller & routes | 1 day | HIGH |
| Frontend payment UI | 1 day | HIGH |
| Testing in sandbox | 2 days | HIGH |
| Nagad integration | 1 day | MEDIUM |
| SSL Commerz integration | 1 day | MEDIUM |
| Security hardening | 1 day | HIGH |
| Production deployment | 1 day | HIGH |

**Total: 8-10 days**

---

## Cost Estimation

### Transaction Fees:

- **bKash**: 1.85% per transaction
- **Nagad**: 1.49% per transaction
- **SSL Commerz**: 2.5% + Gateway fees
- **COD**: Free (but higher return rate)

### Example (50 lakh BDT monthly sales):

| Payment Method | Volume | Fees |
|---------------|--------|------|
| bKash (40%) | 20L | ৳3,700 |
| Nagad (20%) | 10L | ৳1,490 |
| COD (40%) | 20L | ৳0 |
| **Total** | **50L** | **৳5,190/month** |

---

## Next Steps (Immediate)

1. **Register for bKash Merchant:**
   - Visit: https://www.bkash.com/en/business
   - Complete KYC documents
   - Wait for approval (5-7 days)

2. **Set Up Sandbox:**
   - Request sandbox credentials from bKash
   - Test integration locally

3. **Implement Payment Flow:**
   - Add database migrations
   - Create payment services
   - Update frontend UI

4. **Security Audit:**
   - Implement webhook verification
   - Add rate limiting
   - Set up payment logging

---

## Recommendation

For **DhakaCart**, I recommend:

1. **Start with bKash** (most popular in BD)
2. **Add Nagad** (growing fast)
3. **Keep COD** (still important for trust)
4. **Later add SSL Commerz** (for cards)

This covers 90%+ of Bangladeshi payment preferences while keeping integration complexity manageable.

---

**This payment integration will make your project production-ready for the Bangladeshi market!** 🚀💳
