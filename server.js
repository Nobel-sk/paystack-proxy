const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(bodyParser.json());

const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY;

// ✅ Subscription endpoint (Flutter will call this URL)
app.post('/subscribe', async (req, res) => {
  const { email, amount } = req.body;

  try {
    const response = await axios.post(
      'https://api.paystack.co/transaction/initialize',
      {
        email,
        amount, // must be in kobo (i.e., 100 for ₦1.00)
      },
      {
        headers: {
          Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    res.json(response.data); // return the authorization URL to Flutter
  } catch (error) {
    console.error('Paystack error:', error?.response?.data || error.message);
    res
      .status(500)
      .json({ error: error?.response?.data?.message || 'Subscription failed' });
  }
});

// Basic home route (optional)
app.get('/', (req, res) => {
  res.send('FamBite Paystack Proxy Running');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
