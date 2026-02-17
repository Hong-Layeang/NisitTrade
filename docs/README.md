<div align="center">

<p align="center">
  <img src="https://media.tenor.com/ccpKmf7plusAAAAi/anime-sad-wave.gif" width="60" alt="Welcome">&nbsp;
  <img src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=40&duration=3000&pause=1000&color=FFFFFF&center=true&vCenter=true&width=300&lines=NisitTrade" alt="NisitTrade">&nbsp;
  <img width="80" alt="NisitTradeLogo" src="https://github.com/user-attachments/assets/435bbaa4-c485-4461-9881-cd9101e9e659">
</p>

**Campus Marketplace Platform with Verified University Access**

[![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![Express.js](https://img.shields.io/badge/Express.js-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Microsoft OAuth](https://img.shields.io/badge/Microsoft_OAuth-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)](https://docs.microsoft.com/en-us/azure/active-directory/)
[![JWT](https://img.shields.io/badge/JWT-000000?style=for-the-badge&logo=JSON%20web%20tokens&logoColor=white)](https://jwt.io/)

[Features](#key-features) • [Architecture](#system-architecture) • [Security](#security-design) • [Getting Started](#getting-started) • [Roadmap](#future-roadmap)

</div>

---

## 📋 Overview

NisitTrade is a **university-focused marketplace platform** that revolutionizes campus commerce by ensuring every transaction happens within a **verified, trusted community**. Unlike traditional campus marketplaces plagued by fake accounts and scams, NisitTrade leverages **Microsoft domain-restricted authentication** to create a secure trading environment exclusively for verified university students.

### 🎯 The Problem We Solve

| Challenge | NisitTrade Solution |
|-----------|-------------------|
| 🚫 Fake Accounts | Domain-restricted Microsoft OAuth |
| ⚠️ Unverified Users | University email verification |
| 💔 Trust Issues & Scams | Centralized moderation system |
| 🔓 Poor Access Control | Role-based authorization (RBAC) |

---

## ✨ Key Features

### 🛒 **Marketplace Functionality**
- **Full Product Lifecycle**: Create, read, update, and delete product listings
- **Rich Media Support**: Upload up to 8 high-quality images per product
- **Smart Categorization**: Organized category-based browsing
- **Seller Profiles**: Transparent seller information and listing history
- **Centralized Moderation**: Admin oversight for platform integrity

### 🔐 **Authentication & Security**
- **Dual Authentication System**:
  - 🎓 **Students**: Microsoft OAuth (university domain restricted)
  - 👨‍💼 **Admins**: Email/password authentication
- **JWT-Based Sessions**: Secure token management with 7-day expiration
- **Role-Based Access Control**: Granular permission system
- **Domain Validation**: Automatic verification of university email domains

### 👥 **User Roles**

#### Student (User Role)
```
✓ Microsoft OAuth login only
✓ Create & manage product listings
✓ Upload product images (max 8/listing)
✓ Browse marketplace
✓ View seller information
✓ Manage personal profile
```

#### Administrator
```
✓ Email/password authentication
✓ User management
✓ Product moderation
✓ Access admin-only endpoints
✓ Platform policy enforcement
✗ Cannot use Microsoft OAuth
```

---

## 🏗️ System Architecture

NisitTrade employs a **centralized backend architecture** serving both Admin and User applications, ensuring consistency and scalability.

### Backend Stack
```
┌─────────────────────────────────────┐
│         Backend (Centralized)       │
├─────────────────────────────────────┤
│  • Node.js + Express.js             │
│  • Sequelize ORM                    │
│  • JWT Authentication               │
│  • Microsoft OAuth Verification     │
│  • MVC Architecture                 │
└─────────────────────────────────────┘
          │                │
          ▼                ▼
   ┌──────────┐    ┌──────────────┐
   │  Admin   │    │  User (App)  │
   │   Web    │    │   Flutter    │
   └──────────┘    └──────────────┘
```

### Technology Matrix

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Backend Framework** | Express.js | RESTful API server |
| **ORM** | Sequelize | Database abstraction |
| **Authentication** | JWT + Microsoft OAuth | Secure session management |
| **Frontend** | Flutter | Cross-platform mobile app |
| **Architecture** | MVC + Clean Architecture | Maintainability & scalability |
| **HTTP Client** | Dio (Flutter) | API communication |
| **Design Pattern** | Repository Pattern | Data layer abstraction |

---

## 🔒 Security Design

### Student Authentication Flow

```
┌─────────────┐
│   Student   │
└──────┬──────┘
       │
       │ 1. Login via Microsoft
       ▼
┌─────────────────────────────┐
│  Microsoft OAuth Provider   │
└──────────┬──────────────────┘
           │
           │ 2. Returns idToken
           ▼
    ┌──────────────┐
    │   Frontend   │
    └──────┬───────┘
           │
           │ 3. Send idToken to backend
           ▼
    ┌────────────────────────────────┐
    │         Backend Server         │
    ├────────────────────────────────┤
    │ 4. Verify token (JWKS)         │
    │ 5. Validate domain             │
    │    (student.cadt.edu.kh)       │
    │ 6. Check/Create user           │
    │ 7. Block admin accounts        │
    │ 8. Generate server JWT (7d)    │
    └────────────┬───────────────────┘
                 │
                 │ 9. Return JWT
                 ▼
          ┌──────────────┐
          │ Authenticated│
          │   Session    │
          └──────────────┘
```

### Core Security Principles

- **Remote JWKS Verification**: Tokens verified against Microsoft's public keys
- **Domain Restriction**: Only allowed university domains (e.g., `student.cadt.edu.kh`)
- **Role Isolation**: Admin and student authentication completely separated
- **Authorization Middleware**: Protected routes enforce role-based permissions
- **JWT Expiration**: 7-day token lifecycle with refresh capability
- **Environment Configuration**: Domain whitelist managed via environment variables

### Protected Routes

All authenticated endpoints require:

```http
Authorization: Bearer <jwt_token>
```

Middleware validates:
1. Token signature and expiration
2. User existence and status
3. Role-based permissions

---

## 🚀 Getting Started

### Prerequisites

```bash
Node.js >= 16.x
Flutter >= 3.0
PostgreSQL/MySQL
Microsoft Azure Account (OAuth setup)
```

### Backend Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/nisittrade.git
cd nisittrade/backend

# Install dependencies
npm install

# Configure environment variables
cp .env.example .env
# Edit .env with your configuration

# Run database migrations
npx sequelize-cli db:migrate

# Start development server
npm run dev
```

### Frontend Setup

```bash
cd nisittrade/flutter-app

# Install dependencies
flutter pub get

# Configure Microsoft OAuth
# Edit lib/config/auth_config.dart

# Run the app
flutter run
```

### Environment Variables

```env
# Backend (.env)
PORT=3000
DB_HOST=localhost
DB_NAME=nisittrade
DB_USER=your_user
DB_PASS=your_password
JWT_SECRET=your_jwt_secret
ALLOWED_DOMAINS=student.cadt.edu.kh,student.example.edu
MICROSOFT_CLIENT_ID=your_client_id
MICROSOFT_TENANT_ID=your_tenant_id
```

---

## 📁 Project Structure

### Backend (MVC)
```
backend/
├── controllers/      # Request handlers
├── models/          # Sequelize models
├── routes/          # API endpoints
├── middleware/      # Auth & validation
├── services/        # Business logic
├── utils/           # Helper functions
└── config/          # Configuration files
```

### Frontend (Clean Architecture)
```
flutter-app/
├── lib/
│   ├── core/           # Core utilities
│   ├── data/           # Data layer
│   │   ├── models/
│   │   ├── repositories/
│   │   └── datasources/
│   ├── domain/         # Business logic
│   │   ├── entities/
│   │   └── usecases/
│   └── presentation/   # UI layer
│       ├── screens/
│       ├── widgets/
│       └── providers/
```

---

## 🛣️ Future Roadmap

### Phase 1: Multi-University Expansion
- [ ] Support for multiple universities
- [ ] Dynamic domain configuration
- [ ] University verification system

### Phase 2: Enhanced Features
- [ ] In-app messaging system
- [ ] Product rating & review system
- [ ] Advanced search & filters
- [ ] Saved listings & favorites

### Phase 3: Platform Growth
- [ ] Cross-country expansion
- [ ] Admin analytics dashboard
- [ ] Trust score mechanism
- [ ] Automated fraud detection

### Phase 4: Community Features
- [ ] User reputation system
- [ ] Community guidelines enforcement
- [ ] Dispute resolution system
- [ ] Push notifications

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Standards
- Follow ESLint configuration for backend
- Adhere to Dart/Flutter best practices
- Write unit tests for new features
- Update documentation as needed

---

## 👨‍💻 Authors

**NisitTrade Development Team**

- **Project Advisor**: Mr. CHHUON Sopheakmanith
- Project Lead: Hong Layeang
- Backend Developer: Sithav Seavthean, Kong Visal, Soun Sokhunmony
- Frontend Developer: Keo Sivmey, Hong Layeang
- UI/UX Designer: Sithav Seavthean, Kong Visal, Soun Sokhunmony, Keo Sivmey, Hong Layeang

---

## 🙏 Acknowledgments

We would like to express our sincere gratitude to:

* **Mr. CHHUON Sopheakmanith** – Project Advisor, for guidance, technical feedback, and continuous support throughout the development of NisitTrade.
* **Microsoft Azure** – For providing secure OAuth authentication services logic.
* **The open-source community** – For the tools, libraries, and resources that made this project possible.
* **All contributors and testers** – For his valuable feedback and improvements.
* **The University Administration** – For institutional support and encouragement.

---

<div align="center">

**Built with ❤️ for campus communities**

⭐ Star this repo if you find it helpful!

</div>
