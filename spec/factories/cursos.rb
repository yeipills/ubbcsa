FactoryBot.define do
  factory :curso do
    nombre { "MyString" }
    descripcion { "MyText" }
    profesor_id { "" }
    categoria { "MyString" }
  end
end
