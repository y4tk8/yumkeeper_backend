FactoryBot.define do
  factory :video do
    video_id { "abcd1234XYZ" } # YouTube動画を一意に識別するID
    etag { "etag_sample_123" }
    thumbnail_url { "https://example.com/thumbnail.jpg " }
    status { "public" }
    is_embeddable { true }
    is_deleted { false }
    cached_at { Time.current }
    association :recipe
  end
end
