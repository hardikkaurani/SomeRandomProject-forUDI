# 📱 GigTax – SMS-Based Income Tracker for Gig Workers

GigTax is a mobile application that automatically extracts income data from SMS messages and provides a structured financial overview for gig workers, along with real-time tax estimation under presumptive taxation (ITR-4).

---

## 🚀 Problem

Gig workers (Swiggy, Uber, freelancers, etc.) face:

- Fragmented income across platforms  
- No centralized income tracking  
- Confusion around tax filing (especially ITR-4)  
- Difficulty distinguishing income from personal transactions  

---

## 💡 Solution

GigTax converts unstructured SMS data into a clean, categorized income ledger.

### Core Idea:
> Extract → Classify → Aggregate → Estimate Tax

---

## ⚙️ Features (MVP)

- 📩 **Automatic SMS Parsing**
  - Reads incoming SMS messages
  - Detects financial transactions (credited, payout, received)

- 💰 **Income Extraction**
  - Extracts ₹ amounts using regex
  - Identifies potential income sources

- 📊 **Live Income Dashboard**
  - Displays parsed transactions in real-time
  - Shows total earnings

- 🧾 **Tax Estimation (ITR-4)**
  - Supports presumptive taxation:
    - Business: 6% / 8%
    - Professional: 50%

---

## 🧠 How It Works

1. User grants SMS permission  
2. App scans inbox messages  
3. Filters relevant financial messages  
4. Extracts:
   - Amount
   - Sender
   - Timestamp  
5. Displays structured transaction list  
6. Estimates taxable income  

---

## 🏗️ Tech Stack

- **Frontend:** Flutter  
- **Local Storage:** (Planned: SQLite)  
- **SMS Access:** Android SMS APIs (via plugin)  
- **Parsing:** Regex-based extraction  

---

## 📱 Permissions Required

- `READ_SMS`
- `RECEIVE_SMS`

> Used only for extracting transaction-related messages.

---

## ⚠️ Limitations

- SMS formats vary across platforms  
- Cannot always distinguish personal vs income transactions automatically  
- No bank/API integration (MVP constraint)  
- SMS access restricted on some Android versions/devices  

---

## 🔮 Future Improvements

- AI-based classification of transactions  
- Deduplication (bank SMS + platform SMS)  
- Expense tracking  
- Direct ITR filing integration  
- Cloud sync & analytics  

---

## 🧪 Demo Flow

1. Launch app  
2. Grant SMS permission  
3. View parsed income messages  
4. See total earnings  
5. View estimated taxable income  

---

## 🏆 Hackathon Focus

This project prioritizes:

- Real-world problem relevance  
- Practical implementation  
- Working prototype over theoretical completeness  

---

## 📂 Setup Instructions

```mermaid
flowchart TD
    A["git clone https://github.com/Thrizzio/SomeRandomProject-forUDI.git"] --> B["cd SomeRandomProject-forUDI"]
    B --> C["flutter pub get"]
    C --> D["Start Emulator / Connect Device"]
    D --> E["flutter run"]
