# 🛒 DhakaCart E-commerce App - সহজ সেটআপ গাইড

## 📋 প্রয়োজনীয় সফটওয়্যার ইনস্টল করুন

### ১. Docker Desktop ইনস্টল করুন
- **Windows/Mac**: [Docker Desktop ডাউনলোড করুন](https://www.docker.com/products/docker-desktop)
- ইনস্টল করার পর Docker Desktop চালু করুন
- নিশ্চিত করুন যে Docker running আছে (taskbar এ whale icon দেখা যাবে)

### ২. Git ইনস্টল করুন
- [Git ডাউনলোড করুন](https://git-scm.com/downloads)
- ইনস্টল করার সময় সব default option রাখুন

### ৩. Node.js ইনস্টল করুন
- [Node.js LTS ডাউনলোড করুন](https://nodejs.org/)
- ইনস্টল করার সময় "Automatically install necessary tools" চেক করুন

---

## 🚀 DhakaCart চালু করার ধাপ

### ধাপ ১: প্রজেক্ট ডাউনলোড করুন

Terminal/Command Prompt খুলুন এবং এই commands রান করুন:

```bash
# আপনার পছন্দের folder এ যান
cd Desktop

# GitHub থেকে প্রজেক্ট clone করুন (পরে আপনার repo link দিবেন)
git clone https://github.com/yourusername/dhakacart.git

# প্রজেক্ট folder এ ঢুকুন
cd dhakacart
```

### ধাপ ২: Docker দিয়ে সব চালু করুন

```bash
# সব container একসাথে চালু করুন
docker-compose up -d

# অপেক্ষা করুন 30-60 সেকেন্ড (প্রথমবার আরো সময় লাগতে পারে)
```

### ধাপ ৩: ব্রাউজারে দেখুন

- **Frontend (React App)**: http://localhost:3000
- **Backend API**: http://localhost:5000/api/products
- **Database**: localhost:5432

---

## 🎯 কীভাবে ব্যবহার করবেন

### Website Features:
1. **Product List দেখুন**: Homepage এ সব products দেখা যাবে
2. **Cart এ যোগ করুন**: যেকোনো product এ "Add to Cart" ক্লিক করুন
3. **Checkout করুন**: Cart থেকে order complete করুন

### Useful Commands:

```bash
# সব container দেখুন
docker-compose ps

# Logs দেখুন (যদি কোনো সমস্যা হয়)
docker-compose logs

# সব বন্ধ করুন
docker-compose down

# আবার চালু করুন
docker-compose up -d

# সব মুছে নতুন করে শুরু করুন
docker-compose down -v
docker-compose up -d --build
```

---

## 📁 প্রজেক্ট স্ট্রাকচার

```
dhakacart/
├── frontend/          # React application
├── backend/           # Node.js API
├── database/          # PostgreSQL init scripts
├── docker-compose.yml # সব একসাথে চালানোর config
└── README.md          # এই guide
```

---

## 🔧 Troubleshooting (সমস্যা সমাধান)

### সমস্যা: Port already in use
```bash
# Docker containers বন্ধ করুন
docker-compose down

# অন্য applications বন্ধ করুন যা 3000 বা 5000 port ব্যবহার করছে
```

### সমস্যা: Database connection error
```bash
# ১০ সেকেন্ড বেশি wait করুন, তারপর page refresh করুন
# অথবা containers restart করুন:
docker-compose restart
```

### সমস্যা: Changes দেখা যাচ্ছে না
```bash
# Rebuild করুন
docker-compose up -d --build
```

---

## 📤 GitHub এ Push করার নিয়ম

### প্রথমবার:
```bash
# GitHub এ নতুন repository তৈরি করুন (github.com এ গিয়ে)
# তারপর:

git init
git add .
git commit -m "Initial DhakaCart setup"
git branch -M main
git remote add origin https://github.com/yourusername/dhakacart.git
git push -u origin main
```

### পরবর্তীতে Changes করলে:
```bash
git add .
git commit -m "আপনার change এর বর্ণনা"
git push
```

---

## ✅ সফল সেটআপের চেক-লিস্ট

- [ ] Docker Desktop running আছে
- [ ] `docker-compose up -d` সফলভাবে চলেছে
- [ ] http://localhost:3000 এ website দেখা যাচ্ছে
- [ ] Products list লোড হচ্ছে
- [ ] Cart এ product যোগ করা যাচ্ছে
- [ ] Checkout process কাজ করছে

---

## 🆘 সাহায্য দরকার?

- Docker logs দেখুন: `docker-compose logs`
- Container status দেখুন: `docker-compose ps`
- সব restart করুন: `docker-compose restart`

**মনে রাখবেন**: প্রথমবার চালাতে কিছুটা সময় লাগবে কারণ Docker images download করবে!