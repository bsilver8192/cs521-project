This repository has code for our CS521 project analyzing data from the
US DOT Bureau of Transportation Statistics's Freight Analysis Framework.

`domestic_regions.csv` contains a copy of the chart for decoding domestic
region codes from the User's Guide.

`domestic_region_locations.csv` is the result of running `process_regions.sh`.
It is checked in to avoid rapidly exhausting the 2500 queries/day limit on the
Google Maps Geocoding API we're using to build it.
