# Google Maps Setup Instructions

The app now includes Google Maps integration for displaying trip routes and student drop points. To enable the map functionality, you need to add a Google Maps API key.

## Steps to Get Google Maps API Key:

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/

2. **Create or Select a Project**
   - Create a new project or select an existing one

3. **Enable Maps SDK for Android**
   - Go to "APIs & Services" > "Library"
   - Search for "Maps SDK for Android"
   - Click "Enable"

4. **Create API Key**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "API Key"
   - Copy the generated API key

5. **Add API Key to Your App**
   - Open `android/app/src/main/AndroidManifest.xml`
   - Find the line: `android:value="YOUR_API_KEY_HERE"`
   - Replace `YOUR_API_KEY_HERE` with your actual API key

6. **Rebuild the App**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Map Features Implemented:

- **Route Visualization**: Shows the complete trip route with a dashed blue line
- **Drop Points**: Displays markers for each student drop point
- **Start/End Points**: 
  - Green marker for trip start point
  - Red marker for trip end point
  - Blue markers for student drop points
- **My Location**: Shows driver's current location on the map
- **Interactive Map**: Zoom, pan, and tap on markers to see details

## Sample Data:

The app currently uses sample coordinates in Dhaka, Bangladesh area for demonstration:
- 7 drop points along a route
- Each marker shows student information when tapped

## Note:

Without a valid API key, the map will show a gray area with a warning message. The rest of the app functionality will work normally.
