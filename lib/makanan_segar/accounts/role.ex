defmodule MakananSegar.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, :string
    belongs_to :user, MakananSegar.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
  end
end
