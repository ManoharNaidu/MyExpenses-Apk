# My Expenses - Personal Finance Tracker

<div align="center">

![My Expenses](assets/icon/icon2.png)

A powerful and intuitive personal finance tracker built with Flutter and Supabase.

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Contributing](#contributing)

</div>

---

## 📋 Overview

**My Expenses** is a comprehensive personal finance management application that helps you track, analyze, and optimize your spending habits. Whether you're managing your budget for personal use or monitoring business expenses, My Expenses provides an intuitive interface with powerful analytics to keep your finances under control.

Built with **Flutter** for cross-platform compatibility and **Supabase** as the backend database, My Expenses ensures your financial data is securely stored and accessible from anywhere.

---

## ✨ Features

### 📊 Dashboard
- **Quick Overview**: Get an at-a-glance summary of your expenses
- **Expense Tracking**: Easily add, edit, and delete expenses with dates and categories
- **Real-time Updates**: All changes sync instantly across devices
- **Spending Summary**: View total expenses and spending by category

### 📝 History
- **Complete Transaction Log**: Browse through all your historical transactions
- **Filter & Search**: Find specific expenses by date range, category, or amount
- **Detailed Information**: View complete details for each transaction
- **Export Records**: Download or share your transaction history

### 📈 Analytics
- **Charts & Visualizations**: Analyze spending patterns with interactive charts
- **Category Breakdown**: See how much you're spending in each category
- **Time-based Analysis**: Track spending trends over different time periods
- **Insightful Reports**: Generate detailed reports to identify spending patterns

### 🔄 Cross-Platform Support
- **Mobile**: iOS and Android with native performance
- **Desktop**: Windows, macOS, and Linux
- **Web**: Browser-based access to your finances
- **Cloud Sync**: Data synchronization across all platforms

### 🔐 Security & Privacy
- Backend powered by Supabase with secure authentication
- Real-time database with encrypted data transmission
- Personal data remains under your control

---

## 🛠 Prerequisites

Before you begin, ensure you have the following installed on your system:

- **Flutter SDK**: Version 3.10.7 or higher ([Download Flutter](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: Included with Flutter
- **Git**: For version control
- **Android Studio** (for Android development) or **Xcode** (for iOS development)
- **Supabase Account**: Free account at [supabase.com](https://supabase.com)
- **Environment Variables**: `.env` file with Supabase credentials

### Verify Installation

```bash
flutter --version
dart --version
```

---

## 📦 Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/ManoharNaidu/MyExpenses-Apk
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

This command reads the `pubspec.yaml` file and downloads all required packages:
- **supabase_flutter**: Backend database and authentication
- **intl**: Internationalization and date formatting
- **fl_chart**: Beautiful chart visualizations
- **file_saver**: Export transaction records
- **flutter_dotenv**: Environment variable management
- **path_provider**: File system access
- **share_plus**: Share functionality across platforms

### 3. Setup Supabase Backend

1. Create a free account at [supabase.com](https://supabase.com)
2. Create a new project
3. In your Supabase dashboard:
   - Navigate to **Settings** → **API**
   - Copy your **Project URL** and **Anon Key**

### 4. Configure Environment Variables

Use the included templates in the project root:

- `.env.dev` for development
- `.env.prod` for production builds

Set at least this value in both files:

```bash
API_URL=https://your-backend-link/api/v1
```

At runtime, the app loads environment files in this order:

1. `.env.<APP_FLAVOR>` (for example `.env.dev` or `.env.prod`)
2. `.env`
3. `.env.example`

### 5. Generate Launcher Icons (Optional)

If you've updated the app icon:

```bash
flutter pub run flutter_launcher_icons
```

This generates native icons for iOS, Android, and other platforms from `assets/icon/icon2.png`.

---

## 🚀 Running the Application

### Run on Development Device/Emulator

```bash
# List available devices
flutter devices

# Run on default device
flutter run

# Run on specific device
flutter run -d <device_id>
```

### Platform-Specific Execution

**Run with flavor:**
```bash
flutter run --dart-define=APP_FLAVOR=dev
flutter run --dart-define=APP_FLAVOR=prod
```

**Android:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

**Web:**
```bash
flutter run -d chrome
```

**Windows:**
```bash
flutter run -d windows
```

**macOS:**
```bash
flutter run -d macos
```

**Linux:**
```bash
flutter run -d linux
```

### Development Mode with Hot Reload

Once the app is running, press `r` in the terminal for hot reload or `R` for hot restart:

```
r - Hot reload
R - Hot restart
q - Quit
```

Hot reload updates code without losing application state, making development faster.

---

## 🏗 Building the Application

### Build for Release

#### Android
```bash
# Build APK
flutter build apk --release

# Build APK with flavor + endpoint override
flutter build apk --release --dart-define=APP_FLAVOR=prod --dart-define=API_URL=https://your-backend-link/api/v1

# Build App Bundle (for Google Play Store)
flutter build appbundle --release

# Output location: build/app/outputs/flutter-apk/app-release.apk
```

#### iOS
```bash
flutter build ios --release

# Output location: build/ios/iphoneos/
```

#### Web
```bash
flutter build web --release

# Output location: build/web/
```

#### Windows
```bash
flutter build windows --release

# Output location: build/windows/
```

#### macOS
```bash
flutter build macos --release

# Output location: build/macos/
```

#### Linux
```bash
flutter build linux --release

# Output location: build/linux/
```

### Build with Custom Version

```bash
flutter build apk --release --build-number 2 --build-name 1.0.1
```

---

## ⚡ Quick Start for New Users

If you’ve just signed up, follow this practical flow inside the app:

1. **Set currency**
   - Tap currency in the Dashboard header (left side) or use Settings → Change Currency.
2. **Add categories**
   - Go to Settings → Edit Categories and set both income + expense categories.
3. **Add your first transaction**
   - Tap **Add** on Dashboard or History and save an entry.
4. **Upload a bank PDF and review staged rows**
   - Dashboard → Upload Bank PDF → Review staged transactions.
   - Important: only selected rows with both **Type** and **Category** are valid for confirm.
5. **Use Sync when pending > 0**
   - Dashboard top bar cloud icon shows pending operations.
   - Tap it to manually sync queued offline changes.

### What each tab does
- **Dashboard**: summaries, quick add, PDF upload, staged review, currency/sync/export/settings shortcuts.
- **History**: full list with filters (type, month, category), edit/delete, and load-more scrolling.
- **Analytics**: weekly/monthly Income vs Expense trend charts.
- **Settings**: profile, password, categories, currency, dark mode, notifications, privacy/about.

### Local-first behavior (important)
- Add/edit/delete actions appear instantly in local state for responsive UX.
- Sync happens in background and can also be triggered manually.
- If network/API is unavailable, operations remain queued and retry later.

---

## 📱 How to Use My Expenses

### Adding an Expense

1. Open the app and navigate to the **Dashboard** tab
2. Tap the **Add Expense** button (usually a floating action button)
3. Enter the following details:
   - **Amount**: The expense value
   - **Category**: Select from predefined categories (Food, Transport, Entertainment, etc.)
   - **Date**: Choose the transaction date
   - **Description**: Add optional notes (e.g., "Lunch with team")
4. Tap **Save** to record the expense

### Viewing Expense History

1. Navigate to the **History** tab
2. View all your transactions in a list format, sorted by date
3. **Filter transactions** using:
   - Date range selector
   - Category filter
   - Amount range
4. **Tap on a transaction** to view full details
5. **Edit or Delete** by tapping the transaction and selecting the option

### Analyzing Your Spending

1. Go to the **Analytics** tab
2. View interactive charts showing:
   - **Pie Chart**: Expense distribution by category
   - **Bar Chart**: Daily/Weekly/Monthly spending trends
   - **Statistics**: Total expenses, average, highest category
3. **Switch time periods** (Daily, Weekly, Monthly, Yearly)
4. Tap on chart segments to see detailed breakdowns

### Exporting Data

1. In the **History** tab, tap the **Export** button
2. Choose export format:
   - CSV (for spreadsheet applications)
   - PDF (for sharing/printing)
3. Select **Save** or **Share** to store or distribute the file

### Managing Categories

Categories are typically predefined:
- 🍔 Food & Dining
- 🚗 Transport
- 🎬 Entertainment
- 🛍️ Shopping
- 📚 Education
- 💊 Health
- 🏠 Utilities
- ➕ Others

---

## 📁 Project Structure

```
my_expenses/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app/
│   │   ├── theme.dart            # App theme configuration
│   │   └── ...
│   ├── data/
│   │   ├── supabase_client.dart  # Supabase initialization
│   │   └── ...
│   ├── models/                   # Data models (Expense, Category, etc.)
│   ├── screens/
│   │   ├── dashboard_screen.dart # Main dashboard
│   │   ├── history_screen.dart   # Transaction history
│   │   ├── analytics_screen.dart # Analytics & charts
│   │   └── ...
│   ├── widgets/                  # Reusable UI components
│   ├── utils/                    # Helper functions and utilities
│   └── ...
├── android/                      # Android native code
├── ios/                          # iOS native code
├── windows/                      # Windows native code
├── macos/                        # macOS native code
├── linux/                        # Linux native code
├── web/                          # Web platform files
├── pubspec.yaml                  # Flutter dependencies and configuration
├── .env.example                  # Example environment variables
├── README.md                     # This file
└── ...
```

---

## 🔧 Troubleshooting

### Common Issues

**Issue: `flutter pub get` fails**
```bash
# Clear pub cache and try again
flutter pub cache clean
flutter pub get
```

**Issue: Supabase connection error**
- Verify `.env` file exists in the project root
- Check `SUPABASE_URL` and `SUPABASE_ANON_KEY` are correct
- Ensure internet connection is active
- Check Supabase project status in dashboard

**Issue: Hot reload not working**
```bash
flutter clean
flutter pub get
flutter run
```

**Issue: Build fails on Android**
```bash
# Update Android dependencies
flutter doctor -v
flutter pub get
flutter build apk --release
```

**Issue: iOS build fails**
```bash
cd ios
rm -rf Pods
rm Podfile.lock
cd ..
flutter clean
flutter pub get
flutter build ios
```

**Issue: Platform not found**
```bash
flutter doctor
# Install missing dependencies shown in report
```

---

## 📊 Dependencies Overview

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | SDK | Core framework |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| supabase_flutter | ^2.5.8 | Backend & database |
| intl | ^0.19.0 | Date/time formatting |
| fl_chart | ^0.68.0 | Chart visualizations |
| file_saver | ^0.2.14 | Export functionality |
| flutter_dotenv | ^5.1.0 | Environment variables |
| path_provider | ^2.1.2 | File system access |
| share_plus | ^10.1.0 | Share functionality |

---

## 🐛 Reporting Issues

Found a bug? Here's how to report it:

1. Check if the issue already exists on GitHub
2. If not, [create a new issue](https://github.com/yourusername/my_expenses/issues)
3. Include:
   - Description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots (if applicable)
   - Device info (OS, device model, Flutter version)

---

## 🤝 Contributing

We welcome contributions! Here's how to get involved:

### Getting Started
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test thoroughly
5. Commit: `git commit -m 'Add: your feature description'`
6. Push: `git push origin feature/your-feature`
7. Submit a Pull Request

### Code Guidelines
- Follow Dart style conventions ([Effective Dart](https://dart.dev/guides/language/effective-dart))
- Format code: `flutter format .`
- For generated code, run `flutter pub run build_runner build --delete-conflicting-outputs` or `flutter pub run build_runner watch --delete-conflicting-outputs`
- Run linter: `flutter analyze`
- Add comments for complex logic
- Write descriptive commit messages

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👨‍💻 Author

**Your Name**
- GitHub: [@yourname](https://github.com/yourname)
- Email: your.email@example.com

---

## 💡 Future Enhancements

Planned features for upcoming releases:
- Budget management and alerts
- Recurring expense templates
- Multi-currency support
- Advanced reporting and insights
- Expense categorization with ML
- Integration with banking APIs
- Dark mode support
- Offline mode with sync

---

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Backend powered by [Supabase](https://supabase.com)
- Charts provided by [fl_chart](https://pub.dev/packages/fl_chart)
- Icons from [Material Design](https://material.io/resources/icons)

---

## 📞 Support

For support and questions:
- 📧 Email: bheesettimanohar27@gmail.com

---

**Last Updated:** February 5, 2026
**Current Version:** 1.0.0
