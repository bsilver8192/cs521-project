#!/usr/bin/python3

# Creates a domestic_region_locations.csv with latitude+longitude for all
# the domestic regions. The first column is the code and the other columns are
# the latitude/longitude pairs or a redirect. For multiple pairs, we will
# verify they are all "close" (20 miles or something like that) and then use
# the centroid. Redirects are where the data divides a single metropolitan
# area into multiple states, which we don't care about, so we're just going
# to combine the data for all those areas.

# Run this file using process_regions.sh to set up Python correctly.

import csv
import re

import googlemaps

# To generate an API key, go to
# https://developers.google.com/maps/documentation/geocoding/get-api-key#key
# and click the "Get A Key" button and follow the directions. Save it in a file
# named google_maps_geocoding_api_key.txt.

# Type of region codes:
# C: Combined Statistical Area (CSA)
# M: Metropolitan Statistical Area (MSA)
# R: Rest of State - everything in a state not included in a CSA or MSA (RoS)
# S: State that does not include a CSA or MSA
# SM: Whole state is part of MSA

def main():
  with open('google_maps_geocoding_api_key.txt', 'r') as f:
    key = f.read().rstrip()

  gmaps = googlemaps.Client(key=key)

  with open('domestic_regions.csv', 'r', newline='') as explanations:
    with open('domestic_region_locations.csv', 'w') as locations:
      reader = csv.DictReader(explanations, delimiter='\t')
      # Map from the city part of a multi-state areas to the first code we saw
      # for it.
      multistate_areas = {}
      for row in reader:
        split_name = row['Name'].split(', ')
        if len(split_name) == 1:
          if 'Remainder of ' in split_name[0]:
            nice_name = split_name[0][len('Remainder of '):]
          else:
            nice_name = split_name[0]
          candidates = ['%s, %s' % (nice_name, row['State']), nice_name]
        else:
          if len(split_name) > 2:
            raise RuntimeError('Too many pieces in name %s' % repr(split_name))
          # Verify that the second piece says "CT CFS Area", or multiple states
          # including CT like "NY-NJ-CT-PA CFS Area (CT Part)". This is just a
          # sanity check; CT is row['State'] and NY, NJ, and PA are
          # row['Including States'].
          if not re.match('([A-Z]{2}-)*%s(-[A-Z]{2})* CFS Area' % row['State'],
                          split_name[1]):
            raise RuntimeError(
                'Not sure what to do with second piece of %s in %s' %
                (repr(split_name), row['State']))
            if 'Remainder of' in split_name[0]:
              raise RuntimeError('States are not CFS Areas')

          # Deduplicate the parts of an area in different states because we
          # don't care.
          match = re.match('^(.*) \\([A-Z]{2} Part\\)$', split_name[1])
          if match:
            region = match.group(1)
            if region in multistate_areas:
              print('%s,redir:%s' % (row['Code'], multistate_areas[region]),
                    file=locations)
              continue
            else:
              multistate_areas[region] = row['Code']

          # Build up the cross product of all the cities and states. We'll try
          # them all and only keep the ones which return valid results, and then
          # make sure they're all close together and pick the centroid later.
          candidates = []
          for region in split_name[0].split('-'):
            for state in row['Including States'].split() + [row['State']]:
              candidates.append('%s, %s' % (region, state))

        # Try retrieving results for all the candidates and stick them in the
        # file.
        output = [row['Code']]
        found_ids = set()
        for candidate in candidates:
          geocode_result = gmaps.geocode(candidate)
          # If we got multiple results, it's probably a city not in this state
          # so all the guesses are useless for us, so just ignore them.
          if len(geocode_result) > 1:
            pass
          if geocode_result:
            # Don't add the same place twice.
            place_id = geocode_result[0]['place_id']
            if place_id in found_ids:
              continue
            found_ids.add(place_id)

            location = geocode_result[0]['geometry']['location']
            output += [str(location['lat']), str(location['lng'])]
        if len(output) == 1:
          raise RuntimeError('No results in %s' % repr(candidates))
        print(','.join(output), file=locations)

if __name__ == '__main__':
  main()
