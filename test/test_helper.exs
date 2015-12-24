data = [
  {"In the beginning, God created the heavens and the earth."},
  {"The earth was without form and void;"},
  {"and the darkness was on the face of the deep."},
  {"Then God said, 'Let there be a firmament in the midst of the waters,'"},
  {"José Valim"},
  {"Eric Meadows-Jönsson"},
  {"Chris McCord"}
]

ExUnit.start()
Filtrex.Repo.start_link
Filtrex.Repo.delete_all(Filtrex.SampleModel)

for {title} <- data do
  %Filtrex.SampleModel{title: title} |> Filtrex.Repo.insert!
end
