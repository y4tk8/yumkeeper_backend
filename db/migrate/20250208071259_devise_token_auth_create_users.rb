class DeviseTokenAuthCreateUsers < ActiveRecord::Migration[7.2]
  def change
    
    create_table(:users) do |t|
      ## Required
      t.string :provider, :null => false, :default => "email"
      t.string :uid,      :null => false

      ## Database authenticatable
      t.string :encrypted_password, :null => false

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.boolean  :allow_password_change, :default => true

      ## Rememberable
      # t.datetime :remember_created_at

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, :default => 0, :null => false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      ## User Info
      t.string :email, :null => false
      t.string :username
      t.string :profile_image_url

      ## Others
      t.boolean  :is_activated, :default => false
      t.boolean  :is_deleted,   :default => false
      t.string   :role,         :default => "一般"
      t.datetime :last_login_at

      ## Tokens
      t.json :tokens

      t.timestamps
    end

    add_index :users, :email,                       unique: true
    add_index :users, [:uid, :provider],            unique: true
    add_index :users, :reset_password_token,        unique: true
    add_index :users, :confirmation_token,          unique: true
    add_index :users, [:is_activated, :is_deleted]
    add_index :users, :last_login_at
    # add_index :users, :unlock_token, unique: true

    ## CHECK制約
    # username は20文字以内
    execute <<-SQL
      ALTER TABLE users ADD CONSTRAINT check_username_length
      CHECK (char_length(username) <= 20);
    SQL

    # role は一般、管理者、ゲストのいずれか
    execute <<-SQL
      ALTER TABLE users ADD CONSTRAINT check_role
      CHECK (role IN ('一般', '管理者', 'ゲスト'));
    SQL

    # comfirmed_at は NULL か confirmation_sent_at 以降の日時
    execute <<-SQL
      ALTER TABLE users ADD CONSTRAINT check_confirmation_times
      CHECK (confirmed_at IS NULL OR confirmed_at >= confirmation_sent_at);
    SQL
  end
end
