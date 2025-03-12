FactoryBot.define do
  factory :video do
    video_id { "abcd1234XYZ" } # 仮のYouTube Video ID
    etag { "etag_sample_123" } # 仮のETag
    thumbnail_url { "https://example.com/thumbnail.jpg " }
    status { "public" }
    is_embeddable { true }
    is_deleted { false }
    cached_at { Time.current }
    association :recipe
  end
end
