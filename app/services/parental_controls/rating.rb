# frozen_string_literal: true

module ParentalControls
  # Maps content certifications (MPAA / US TV ratings) to the minimum
  # viewer age the rating is designed for.  A child account may only see
  # and play titles whose rating age is <= its configured max_rating_age.
  module Rating
    # Content that cannot be verified as age-appropriate is treated as
    # adult-only (fail-closed): unrated titles and lookups we could not
    # resolve both map here.
    UNKNOWN_AGE = 18

    # Minimum viewer age per certification.  Sources return a mix of MPAA
    # ("PG-13"), US TV ("TV-MA") and legacy values ("GP").  Censorship
    # seals like "Passed"/"Approved" (Production Code, pre-1968) are NOT
    # age ratings and deliberately map to UNKNOWN_AGE: their content was
    # never rated for any age group.
    AGE_BY_CERTIFICATION = {
      "G" => 0, "TV-G" => 0, "TV-Y" => 0, "U" => 0, "ALL" => 0,
      "TV-Y7" => 7, "TV-Y7-FV" => 7,
      "PG" => 8, "GP" => 8, "TV-PG" => 8,
      "PG-13" => 13, "M" => 13,
      "TV-14" => 14,
      "R" => 17, "TV-MA" => 17, "MA" => 17,
      "NC-17" => 18, "X" => 18, "AO" => 18
    }.freeze

    # Certifications that explicitly mean "no rating assigned" (and any
    # unrecognized value) map to UNKNOWN_AGE like unknown values.
    module_function

    def min_age_for(certification)
      key = normalize(certification)
      return UNKNOWN_AGE if key.blank?

      AGE_BY_CERTIFICATION.fetch(key, UNKNOWN_AGE)
    end

    def normalize(certification)
      certification.to_s.gsub(/\s+/, " ").strip.upcase
    end
  end
end
