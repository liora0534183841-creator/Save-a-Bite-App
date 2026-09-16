# 🍔 Save A Bite

An advanced community application designed to reduce food waste by connecting local businesses (bakeries, restaurants, and supermarkets) with consumers seeking discounted surplus food packages.

## 👥 The Team
This project was developed collaboratively by: Hodia Kobani, Shira Gal, Liora Levi, Rivka Edri, and Hadar Biton.

## ✨ Key Features & User Roles
The application features a smart authentication system that automatically routes users to their respective dashboards based on their role (Customer, Business, or Admin). It also includes a system-wide Dark Mode toggle for better UX.

### 👤 Customers
*   **Discovery:** Browse available food packages using a detailed List View or an interactive Map View powered by Google Maps.
*   **Search & Filter:** Find specific deals by city autocomplete or free-text search (business/package name).
*   **Order Management:** Claim packages, navigate directly to the business for pickup, mark items as collected, and leave ratings/reviews for the business.

### 🏪 Businesses
*   **Secure Onboarding:** Registration requires uploading a business license and logo, ensuring only verified businesses join the platform.
*   **Inventory Management:** Easily upload new surplus packages with specific pricing, dates, and designated collection hours.
*   **Order Tracking:** Monitor active packages, track customer orders, and manage inventory directly from the business dashboard.

### 🛡️ System Admin
*   **Verification Dashboard:** A dedicated interface to review pending business registrations.
*   **Document Review:** Download and verify business licenses and registration documents.
*   **Access Control:** Approve or reject business applications with a single click.

## 🚀 Installation & Running
To run the application locally and ensure proper Google Maps rendering and data fetching, use the following commands:

```bash
# Clone the repository
git clone https://github.com/liora0534183841-creator/Save-a-Bite-App.git
# Install dependencies
flutter pub get

# Run on Chrome with web security disabled (for API/CORS compatibility during development)
flutter run -d chrome --web-browser-flag "--disable-web-security"
