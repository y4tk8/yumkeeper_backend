FactoryBot.define do
  factory :video do
    video_id { "abcd1234XYZ" } # 仮のYouTube Video ID
    etag { "etag_sample_123" } # 仮のETag
    thumbnail { "https://example.com/thumbnail.jpg " }
    status { "public" }
    is_embeddable { true }
    is_deleted { false }
    association :recipe
  end
end
