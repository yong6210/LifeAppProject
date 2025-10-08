# Firebase Setup Guide

1. **Create Firebase projects** for each app flavor (dev/staging/prod).
2. Enable **Authentication** providers required by the product:
   - Anonymous (upgrade flow)
   - Email/Password
   - Google
   - Sign in with Apple (Bundle ID/key configuration required on Apple portal)
3. Enable **Cloud Firestore** in production mode. Choose a region close to your core user base.
4. Install the FlutterFire CLI and generate `firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<your-project-id>
   ```
   Replace the placeholder `lib/firebase_options.dart` with the generated file.
5. Copy the generated `GoogleService-Info.plist` and `google-services.json` into the iOS and Android projects (`ios/Runner/` and `android/app/`).
6. Configure iOS URL schemes for Google/Apple sign-in and update the `LSApplicationQueriesSchemes` if required.
7. Update Android `AndroidManifest.xml` with the correct OAuth redirect scheme for Google sign-in.
8. Deploy the Firestore security rules from `firebase/firestore.rules` once customised for your project IDs:
   ```bash
   firebase deploy --only firestore:rules
   ```

> After completing these steps, run the app once to ensure Firebase initializes correctly. The sync controller will try to sign in anonymously if no user session exists.
