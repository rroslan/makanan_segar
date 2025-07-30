defmodule MakananSegar.Repo.Migrations.AddVendorBusinessFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :business_name, :string
      add :phone, :string
      add :business_description, :text
      add :business_hours, :text
      add :business_type, :string
      add :business_registration_number, :string
      add :website, :string
      add :social_media, :map
    end
  end
end
