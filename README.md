# Mind Garden
Mind Garden is a personal journaling and mood tracking application developed with Flutter and Supabase. It provides a secure and intuitive environment for users to record thoughts, track daily moods, and visualize emotional patterns and writing habits over time.

# Features
- User Authentication: Secure sign-up and login via Supabase Authentication.
- Onboarding Experience: An initial guided tour for new users, introducing core app functions before registration.
- Mood Tracking: Effortlessly record daily moods using emojis.
- Journaling: Create detailed entries with titles and content.
- Image Attachment: Attach images to journal entries.
- Tagging System: Organize entries with custom tags for efficient categorization and search.
- Color Coding: Assign colors to entries for visual organization.
- Date Selection: Choose specific entry dates.
- Entry Management: View, edit, and delete past entries.
- User Profile: Displays the user's nickname on the home page.
- Statistics Page: Provides various insights into journaling habits and mood trends, including:
  - Total Entries: Number of entries created.
  - Current Streak: Tracks consecutive journaling days.
  - Mood Bar: Visualizes mood distribution over the last 7 days.
  - Most Frequently Recorded Tags: Identifies most used tags.
  - Average Entry Length: Insight into average word count.
  - Total Words Written: Aggregate word count.
- Theme Switching: Toggle between light (pastel) and dark (night) modes for a personalized viewing experience. Theme preference is saved locally.
- Responsive Interface: Adapts seamlessly across various screen sizes (mobile and tablet).

# Technologies Utilized
- Flutter: Google's UI toolkit for developing native applications across mobile, web, and desktop from a single codebase.
- Supabase: An open-source Firebase alternative, offering Authentication (user management), PostgreSQL Database (journal entries, profiles), and Storage (image uploads like entry_images).
- Additional Libraries: Integrates google_fonts for custom typography, intl for date formatting, image_picker for gallery image selection, path for file path manipulation, and shared_preferences for local data storage.

# Application Flow
1. Application Launch: The app starts on the LoginPage.
2. Registration: Users can select "Don't have an account? Sign Up" to proceed to the OnboardingPage.
3. Onboarding: Navigate introductory slides; a "Skip" button is available. The "Get Started" button on the final slide directs to the SignUpPage.
4. Account Creation: On the SignUpPage, users provide a nickname, email, and password. Upon successful registration, profile data (user_id, nickname, email) is stored in the profiles table, and the user is redirected to the LoginPage.
5. Login: Users enter credentials on the LoginPage. Successful authentication leads to HomePage.
6. Home Page: Displays a welcome message, mood selection interface, and a list of prior entries.
7. Entry Editor: Allows creating or editing entries, with options for title, content, date, image, tags, color, and mood.
8. Statistics Page: Presents various statistical insights on journaling habits and mood trends.
9. Theme Toggle: Moon/sun icon on the app bar enables theme switching.
10. Responsive Interface: Design ensures optimal viewing and interaction across diverse screen dimensions.
