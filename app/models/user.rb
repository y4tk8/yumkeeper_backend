class User < ActiveRecord::Base
  # Devise の設定
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :confirmable
  # :lockable, :timeoutable, :trackable, :omniauthable, :rememberable

  # DeviseTokenAuth の設定
  include DeviseTokenAuth::Concerns::User

  has_many :recipes, dependent: :destroy
  has_one_attached :profile_image

  # メールアドレスの形式チェック。英字の大文字小文字を区別しない。
  VALID_EMAIL_REGEX = /\A[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\z/i
  validates :email, format: { with:    VALID_EMAIL_REGEX,
                              message: "メールアドレスは正しい形式で入力してください" }
  before_save :downcase_email

  # パスワードは英字(大文字 or 小文字)と数字は必須。記号は任意。合計8文字以上。
  VALID_PASSWORD_REGEX = /\A(?=.*[A-Za-z])(?=.*\d)(?!.*\s)[A-Za-z\d!@#$%^&*\-_+=]{8,128}\z/
  validates :password, format: { with:    VALID_PASSWORD_REGEX,
                                 message: "パスワードは英字と数字を含んだ8文字以上にしてください" }, if: :password_required?

  validate  :validate_profile_image
  validates :username, length: { maximum: 20 }

  # Devise Token Auth のサインイン時に退会済みユーザーは認証エラーにする
  def active_for_authentication?
    super && !is_deleted
  end

  # 認証エラー時のDeviseデフォルトメッセージをオーバーライド
  def inactive_message
    is_deleted ? "退会済みのユーザーです。" : super
  end

  # NOTE: ユーザー論理削除の際に呼び出す
  def delete_recipes
    recipes.destroy_all
  end

  # プロフィール画像のURLを取得
  def profile_image_url
    if profile_image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(profile_image, only_path: true)
    else
      default_image_url
    end
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  # Devise の既定パスワードバリデーションを適用
  def password_required?
    new_record? || password.present? || password_confirmation.present?
  end

  # プロフィール画像のバリデーション（サイズと形式）
  def validate_profile_image
    return unless profile_image.attached?

    if profile_image.blob.byte_size > 5.megabytes
      errors.add(:profile_image, "は5MB以下にしてください")
    end

    unless profile_image.blob.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
      errors.add(:profile_image, "はJPEG, PNG, GIF, WEBP形式のみアップロード可能です")
    end
  end

  # デフォルトのプロフィール画像を取得
  # NOTE: AWS構築を終えたらS3のURLを書く
  def default_image_url
    if Rails.env.production?
      # S3 のURL
    else
      "/default_profile_image.png" # 開発・テスト環境用のローカル相対パス
    end
  end
end
