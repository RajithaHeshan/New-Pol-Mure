# Project Proposal: New-Pol-Mure iOS Application

**Prepared by:** Rajitha Heshan Dunumala  
**Platform:** iOS (Swift / SwiftUI)  
**Date:** May 2026

---

## 1. What is This App?

New-Pol-Mure is a mobile app for buying and selling coconuts in Sri Lanka. It connects two groups of people — coconut farmers (sellers) and businesses that need coconuts (buyers). These buyers can be retailers, processors, or exporters.

Right now, coconut trading in Sri Lanka happens mostly through middlemen or phone calls. There is no clear and fair way for farmers to see who wants to buy, or for buyers to find fresh stock quickly. This app solves that problem by giving both sides a single platform to trade, track deals, and manage contracts directly from their phones.

The app has one login but two different experiences — one for sellers and one for buyers. After login, the app shows the right screens based on the user's role.

---

## 2. Who Uses This App?

**Sellers (Farmers):**
- Coconut farmers who want to list their harvest and get the best price
- They want to find buyers without going through middlemen
- They want to see who is interested and accept the best deal

**Buyers (Businesses):**
- Retailers, processors, or exporters who need a regular supply of coconuts
- They want to find fresh stock, bid on harvests, or send direct offers
- They want to manage contracts and payments in one place

---

## 3. Features Already Built

### 3.1 User Registration and Login

Both buyers and sellers can create an account with their email and password. During registration, sellers enter their estate location, yield details, and certification level. Buyers enter their business type, typical volume needed, and their sourcing location.

When a user logs in again, the app remembers who they are and takes them straight to their dashboard without asking them to log in again.

### 3.2 Buyer: Find Sellers (Discovery Dashboard)

Buyers can search for coconut sellers near them. They can filter results by:
- All sellers
- High-volume sellers (5,000+ nuts)
- Sellers whose harvest is ending soon
- Sellers nearest to the buyer

The app also shows a smart list of the best-matched sellers at the top, ranked using a built-in AI model. This helps buyers quickly find the most suitable seller without reading through every listing.

### 3.3 Buyer: Live Bidding

Buyers can place bids on active harvest lots posted by sellers. The app shows the current highest bid in real time. If another buyer bids higher, the app sends a notification to alert the buyer that they have been outbid. This creates a fair, open auction for every harvest.

### 3.4 Buyer: Urgent Board

If a buyer urgently needs coconuts, they can post an urgent request. This shows up on the seller's side as a priority signal. Sellers can then send a direct offer to that buyer. This feature makes sure urgent needs are filled faster.

### 3.5 Buyer: Activity Dashboard

This shows the buyer everything happening with their account:
- All bids they have placed and their current status
- Offers sent to them by sellers
- Past transactions with prices and fees
- All their active contracts

### 3.6 Buyer: Performance Dashboard

This shows the buyer how they are doing over time. They can see:
- Total nuts they have bought (weekly, monthly, yearly)
- How often they win bids
- How much they spend on auctions vs direct offers
- Smart insights, like whether their buying cost is above or below the market average

### 3.7 Seller: Dashboard (Find Buyers)

Sellers can search for registered buyers near them. They can filter by:
- All buyers
- High-capacity buyers (10,000+ nuts)
- Buyers with urgent needs
- Nearest buyers

Like the buyer side, the seller dashboard also uses an AI model to recommend the most suitable buyers at the top. The seller also sees a summary of their escrow totals and active offers.

### 3.8 Seller: Create a Harvest Listing

Sellers can post their available harvest with details like:
- Property name
- Quantity of nuts
- Quality grade (Premium, Standard, Processing, Mixed)
- Starting price
- Estate location on a map
- Harvest date

Once posted, the harvest goes live and buyers can start bidding on it. The listing runs for 7 days.

### 3.9 Seller: Direct Offers (Pitches)

Sellers can also send direct price offers to specific buyers without going through an auction. This is called a "pitch." If another seller sends a higher pitch to the same buyer, the first seller gets a notification that they have been outpitched.

### 3.10 Seller: Activity Dashboard

This shows sellers:
- All their sent pitches and status
- Bids coming in on their harvest listings
- Completed transactions
- Their active contracts

### 3.11 Contract Management (Both Sides)

When a bid or pitch is accepted, a contract is created between the buyer and seller. The contract goes through clear steps:
1. Escrow secured (funds are held safely)
2. Buyer locks funds
3. Inspection date is set
4. Buyer travels to estate for quality check
5. Funds are released after handover
6. Both sides can leave a rating

If there is a quality or price issue, either side can raise a dispute with a counter-offer, and they can negotiate within the app.

### 3.12 Seller: Performance Dashboard

Sellers can see:
- Total nuts they have sold over time
- How successful their pitches are (accepted vs total sent)
- Revenue from auctions vs direct pitches
- Insights about their pricing vs market average

### 3.13 Market Analytics (Price Trends)

Both buyers and sellers can see coconut price trends across 11 Sri Lankan zones. The charts show the average price per nut over the past 7 days, how prices are changing, and a 7-day price forecast. This helps both sides make smarter decisions about when to buy or sell.

### 3.14 Rating System

After every completed contract, both the buyer and the seller can rate each other with 1–5 stars and a comment. These ratings build a trust score that is shown on their profiles.

### 3.15 User Profile

Both buyers and sellers can view and edit their profile details — name, phone number, location, and their trade-specific details. They can also sign out.

---

## 4. Mandatory Advanced Features

### 4.1 Push Notifications

**What it does:**  
The app sends real-time alerts to users even when they are not actively using the app.

**How it is used in this app:**
- A buyer gets a notification when another buyer outbids them in an auction
- A seller gets a notification when a buyer places a bid on their harvest
- A seller gets a notification when a buyer sends them an offer
- A seller gets a notification when another seller outpitches them on the same buyer
- Buyers also receive a pick-up reminder before their scheduled inspection date

**Why it matters:**  
Coconut trading is time-sensitive. An auction that ends in hours, or a bid that gets overtaken, can mean a seller loses a good deal or a buyer misses the stock they need. Without push notifications, users would have to constantly open the app to check for updates. With push notifications, they can act immediately when something important happens — which keeps trading moving and reduces missed opportunities.

---

### 4.2 Core Data (Offline Storage)

**What it does:**  
Core Data is Apple's built-in database system for iPhones. This app uses it to store a copy of important information on the device itself, not just on the internet.

**How it is used in this app:**
- The app saves a copy of the user's bids, offers, contracts, and transactions on the device
- When the app opens, it loads this saved data immediately while it waits for the latest data from the internet
- The user's profile is also saved locally so the app knows who is logged in even if the internet is slow
- When the user logs out, their local session is deleted from Core Data for security

**Why it matters:**  
Internet connectivity in rural farming areas in Sri Lanka is not always reliable. If a farmer opens the app in an area with a weak signal, they should still be able to see their contracts and past transactions. Core Data makes this possible by showing the last saved version of their data while the app tries to reconnect. This makes the app feel fast and reliable, even in poor network conditions.

---

### 4.3 Face ID (Biometric Authentication)

**What it does:**  
Face ID lets users log in by looking at their phone instead of typing a password.

**How it is used in this app:**
- When a registered user opens the app, they can choose to log in with Face ID instead of their email and password
- If Face ID fails or the device does not support it, the app falls back to email/password login
- The app stores the user session in Core Data after a successful Face ID login so the next session is also seamless

**Why it matters:**  
Farmers and buyers often use their phones quickly — on the field, in the market, or on the road. Typing a password every time is slow and annoying. Face ID makes it fast and secure to get into the app. It also adds a layer of security because only the registered user's face can unlock the account. This builds trust, especially when contracts and payments are involved.

---

## 5. Advanced Features

### 5.1 MapKit (Interactive Maps)

**What it does:**  
MapKit is Apple's built-in mapping system. It lets the app show real maps inside the screen, drop pins on locations, and help users pick a location by tapping on a map.

**How it is used in this app:**
- During seller registration, the seller taps on a map to mark the exact location of their coconut estate
- During buyer registration, the buyer uses a map to set their sourcing region
- When creating a harvest listing, the seller can update the estate location on a map
- When a buyer searches for sellers, the app uses the locations stored from map selection to calculate distance and show nearby results
- The app also uses 11 pre-defined Sri Lankan zones based on geographic coordinates to group price data by region (Colombo, Galle, Kandy, Kurunegala, Puttalam, Jaffna, Trincomalee, Badulla, Matara, Ratnapura, Anuradhapura)

**Why it matters:**  
Location is one of the most important factors in coconut trading. A buyer wants to find sellers nearby to reduce transport costs. A seller wants to connect with buyers who can actually reach them. Manually typing an address is error-prone and unreliable in rural areas where roads do not have standard addresses. With MapKit, both buyers and sellers just tap on the map to set their location accurately. This also powers the "Nearest to Me" filter in both dashboards, which makes finding the right trading partner fast and practical.

---

### 5.2 EventKit (Calendar Integration)

**What it does:**  
EventKit is Apple's framework for accessing and writing to the device's Calendar app. The app uses this to add important trade events directly to the user's phone calendar.

**How it is used in this app:**
- When a buyer confirms an inspection date on a contract, the app adds a "Pick-up" event to the buyer's calendar with the time, location, and contract details
- When a seller's contract moves to the inspection stage, the app adds a "Buyer Arriving" event to the seller's calendar with the buyer's name, contract value, and a reminder
- Both the seller and buyer get two automatic reminders — one 24 hours before and one 1 hour before the inspection
- The calendar event also includes a deep link that takes the user directly back to the relevant contract in the app

**Why it matters:**  
A failed inspection is a big problem in coconut trading. If the seller is not at the estate when the buyer arrives, or if the buyer forgets the date, the whole contract falls apart and both sides lose money and time. By automatically adding inspection events to the phone's calendar — which most people already check every day — the app makes it much harder to forget. The built-in reminders ensure both parties are ready. This reduces no-shows and builds more trust between traders.

---

### 5.3 CoreML (Machine Learning)

**What it does:**  
CoreML is Apple's framework for running AI models directly on the iPhone. This means the app can make smart predictions and recommendations without sending data to an external server.

**How it is used in this app:**

**Buyer and Seller Matching (RecommendationEngine):**  
The app has an AI model that scores how well a seller matches a buyer (and vice versa). It looks at factors like:
- How close they are to each other (distance in km)
- Whether the seller's yield matches what the buyer needs in volume
- Export certifications (important for exporter buyers)
- Price difference between what the seller asks and what the buyer usually pays
- Past transaction history between the two

Based on this score, the top 5 most-suitable sellers or buyers are shown at the top of the dashboard. This is more useful than a random list because it puts the most relevant matches first.

**7-Day Price Forecast (PriceForecastEngine):**  
The app has a second AI model that predicts what the coconut price will be 7 days from now in any given zone. It uses:
- The current zone
- The current month and day of the week
- The average price over the past week
- The previous week's average price
- The percentage change in price
- How many transactions happened recently

This forecast is shown in the Market Analytics section with a trend line.

**Why it matters:**  
Without smart recommendations, buyers and sellers would have to scroll through dozens of profiles to find a good match. The AI model removes that effort by putting the best options first. This saves time and increases the chance of a successful deal.

For pricing, both buyers and sellers need to know whether the price is going up or down before they make a decision. A seller might hold off posting a harvest if prices are expected to rise next week. A buyer might lock in a deal now if they see prices going up. The 7-day forecast gives both sides useful information to make smarter decisions — something that no middleman or phone call can offer in real time.

Running both models on the device (using CoreML) also means the app works without internet for recommendations and forecasts, and no personal trading data is sent to an external AI server, which protects user privacy.

---

## 6. Summary of All Features

| Feature | Type | Status |
|---|---|---|
| User Registration (Buyer and Seller) | Core | Done |
| Email/Password Login | Core | Done |
| Buyer Discovery Dashboard | Core | Done |
| Seller Discovery Dashboard | Core | Done |
| Live Bidding (Auction) | Core | Done |
| Direct Offers / Pitches | Core | Done |
| Urgent Board | Core | Done |
| Contract Management | Core | Done |
| Dispute and Counter-offer | Core | Done |
| Rating System | Core | Done |
| Performance Analytics (Buyer and Seller) | Core | Done |
| Market Price Trends | Core | Done |
| Profile Management | Core | Done |
| Siri Shortcuts Integration | Core | Done |
| Push Notifications | Mandatory Advanced | Done |
| Core Data (Offline Storage) | Mandatory Advanced | Done |
| Face ID Authentication | Mandatory Advanced | Done |
| MapKit (Location Picking and Zone Maps) | Advanced | Done |
| EventKit (Calendar Events and Reminders) | Advanced | Done |
| CoreML (AI Matching and Price Forecast) | Advanced | Done |

---

## 7. Technology Stack

| Component | Technology |
|---|---|
| Language | Swift |
| UI Framework | SwiftUI |
| Backend / Database | Firebase (Firestore) |
| Authentication | Firebase Auth |
| Offline Storage | Core Data |
| Maps | MapKit |
| Calendar | EventKit |
| Machine Learning | CoreML |
| Push Notifications | UNUserNotificationCenter |
| Biometric Login | LocalAuthentication (Face ID) |
| Siri Integration | NSUserActivity / Intent Extension |

---

## 8. App Architecture

The app follows the MVVM pattern (Model-View-ViewModel). Each screen has its own ViewModel that handles data and logic, while the View only handles what the user sees. Data from Firebase is kept in sync using real-time listeners, so the screen updates automatically when something changes on the server — like a new bid coming in or a contract status changing.

Core Data acts as a local copy of the most important data. When the app opens, it loads from Core Data first, then updates from Firebase. This makes the app fast to start and keeps it working even with a poor connection.

---

## 9. Why This App is Useful

The coconut industry in Sri Lanka employs many small farmers who do not have access to fair markets. Most of them rely on middlemen who take a large cut of the profits. New-Pol-Mure removes the middleman by giving farmers and buyers a direct line of communication with fair, open pricing.

The auction system ensures sellers get the best possible price through competition. The direct offer system gives buyers the option to secure stock quickly without waiting for an auction to end. The contract system keeps both sides accountable and reduces the risk of disputes. The analytics tools help both buyers and sellers understand the market and make better decisions.

This app is practical, built for real use in Sri Lanka, and designed to work in areas where internet is not always perfect.

---

*End of Proposal*
