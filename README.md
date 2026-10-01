# NASA APOD iOS Test

UIKit iOS app with `Main.storyboard` for browsing NASA Astronomy Picture of the Day entries by selected month and year.

## Features

- Select year and month
- Fetch APOD items from NASA Science `apod-basic` API by selected month
- Show list of all entries in the selected month
- Show title, date, explanation, copyright, media type, and image/video URL
- Tap an item to open a detail screen
- Handles image and video APOD entries
- Loading, empty, and error states

## API Key

The app reads `NASA_API_KEY` from Info.plist. The Xcode project is configured to load this value from `Config/Secrets.xcconfig`.

Current endpoint:

```text
https://science.nasa.gov/wp-json/wp/v2/apod-basic/
```

For a real submission, create a NASA API key at:

https://api.nasa.gov/

Then add the key locally:

```xcconfig
NASA_API_KEY = DEMO_KEY
```

Avoid committing a private API key to a public repository.

## Run

Open `NASAAPOD.xcodeproj` in Xcode, choose an iPhone simulator, then press Run.

The app launches from `Resources/Main.storyboard`, which contains the initial navigation controller and `APODListViewController`.

## Project Structure

- `Models/APODItem.swift`: API response model
- `Services/APODService.swift`: NASA API client
- `Resources/Main.storyboard`: storyboard entry point
- `Controllers/APODListViewController.swift`: month picker and APOD list
- `Controllers/APODDetailViewController.swift`: APOD detail screen
- `Controllers/APODTableViewCell.swift`: list cell UI
- `Extensions/Date+Month.swift`: month date range helpers
# persec2026-ios-dev-practice-atipatai.k-new
