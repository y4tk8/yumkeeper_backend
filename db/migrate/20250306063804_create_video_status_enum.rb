class CreateVideoStatusEnum < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      CREATE TYPE video_status AS ENUM ('public', 'private', 'unlisted');
    SQL
  end

  def down
    execute "DROP TYPE video_status;"
  end
end
