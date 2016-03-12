data = [
  {"In the beginning, God created the heavens and the earth.",
    %Ecto.Date{year: 2016, month: 1, day: 1}, 99.9, 256},
  {"The earth was without form and void;",
    %Ecto.Date{year: 2016, month: 2, day: 10}, 84.2, 200},
  {"and the darkness was on the face of the deep.",
    %Ecto.Date{year: 2016, month: 3, day: 20}, 15.7, 132},
  {"Then God said, 'Let there be a firmament in the midst of the waters,'",
    %Ecto.Date{year: 2016, month: 4, day: 2}, 8.2, 5},
  {"José Valim",
    %Ecto.Date{year: 2016, month: 5, day: 4}, 45.3, 30},
  {"Eric Meadows-Jönsson",
    %Ecto.Date{year: 2016, month: 6, day: 6}, 10.4, 24},
  {"Chris McCord",
    %Ecto.Date{year: 2016, month: 7, day: 8}, 67.0, 10}
]

ExUnit.start()
Filtrex.Repo.start_link
Filtrex.Repo.delete_all(Filtrex.SampleModel)

for {title, date_column, rating, upvotes} <- data do
  %Filtrex.SampleModel{title: title, date_column: date_column, rating: rating, upvotes: upvotes}
    |> Filtrex.Repo.insert!
end
