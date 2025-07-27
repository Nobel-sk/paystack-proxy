require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');
const admin = require('firebase-admin');

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_RTDB_URL,
});

const app = express();
app.use(cors());
app.use(bodyParser.json());

const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY;

if (!PAYSTACK_SECRET_KEY) {
  console.error('Missing PAYSTACK_SECRET_KEY');
  process.exit(1);
}

// POST /subscribe
app.post('/subscribe', async (req, res) => {
  const { email, amount } = req.body;

  try {
    const response = await axios.post(
      'https://api.paystack.co/transaction/initialize',
      {
        email,
        amount,
        callback_url: `${process.env.BASE_URL}/callback`,
      },
      {
        headers: {
          Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    res.json(response.data);
  } catch (error) {
    console.error('Paystack initialize error:', error.response?.data || error.message);
    res.status(500).json({ error: 'Subscription failed' });
  }
});

// GET /callback
app.get('/callback', (req, res) => {
  res.send(`
    <html>
      <body style="font-family: sans-serif; text-align: center; margin-top: 40px;">
        <h2>🎉 Payment Successful!</h2>
        <p>You may now return to the FamBite app.</p>
      </body>
    </html>
  `);
});

// POST /webhook (Paystack)
app.post('/webhook', async (req, res) => {
  const event = req.body;
  if (event.event === 'charge.success') {
    const email = event.data.customer.email;
    const reference = event.data.reference;

    const db = admin.database();
    const snapshot = await db.ref('users').orderByChild('email').equalTo(email).once('value');

    if (snapshot.exists()) {
      snapshot.forEach(child => {
        child.ref.update({
          subscription: { active: true, reference },
        });
      });
      console.log(`Subscription activated for ${email}`);
    }
  }
  res.sendStatus(200);
});

app.get('/', (_, res) => res.send('FamBite Paystack Proxy is running'));
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server listening on ${PORT}`));
