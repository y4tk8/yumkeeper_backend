class User < ActiveRecord::Base
  has_many :recipes, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :confirmable
  # :lockable, :timeoutable, :trackable, :omniauthable, :rememberable

  # DeviseTokenAuth の設定
  include DeviseTokenAuth::Concerns::User

  # Devise の既定バリデーションに追加
  # メールアドレスの形式チェック。英字の大文字小文字を区別しない。
  VALID_EMAIL_REGEX = /\A[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\z/i
  validates :email, format: { with:    VALID_EMAIL_REGEX,
                              message: "メールアドレスは正しい形式で入力してください" }
  before_save :downcase_email

  # パスワードは英字(大文字 or 小文字)と数字は必須。記号は任意。合計8文字以上。
  VALID_PASSWORD_REGEX = /\A(?=.*[A-Za-z])(?=.*\d)(?!.*\s)[A-Za-z\d!@#$%^&*\-_+=]{8,128}\z/
  validates :password, format: { with:    VALID_PASSWORD_REGEX,
                                 message: "パスワードは英字と数字を含んだ8文字以上にしてください" }, if: :password_required?

  # Devise Token Auth のサインイン時に退会済みユーザーは認証エラーにする
  def active_for_authentication?
    super && !is_deleted
  end

  # 認証エラー時のDeviseデフォルトメッセージをオーバーライド
  def inactive_message
    is_deleted ? "退会済みのユーザーです。" : super
  end

  # ユーザーの登録レシピ数を返す
  def recipe_count
    recipes.count
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  # Devise の既定パスワードバリデーションを適用
  def password_required?
    new_record? || password.present? || password_confirmation.present?
  end
end
