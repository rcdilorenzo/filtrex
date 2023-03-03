data = [
  {"In the beginning, God created the heavens and the earth.", {{2016, 1, 1}, {12, 34, 56}}, 99.9,
   256},
  {"The earth was without form and void;", {{2016, 2, 10}, {12, 34, 56}}, 84.2, 200},
  {"and the darkness was on the face of the deep.", {{2016, 3, 20}, {12, 34, 56}}, 15.7, 132},
  {"Then God said, 'Let there be a firmament in the midst of the waters,'",
   {{2016, 4, 2}, {12, 34, 56}}, 8.2, 5},
  {"José Valim", {{2016, 5, 4}, {12, 34, 56}}, 45.3, 30},
  {"Eric Meadows-Jönsson", {{2016, 6, 6}, {12, 34, 56}}, 10.4, 24},
  {"Chris McCord", {{2016, 7, 8}, {12, 34, 56}}, 67.0, 10}
]

ExUnit.start()
Filtrex.Repo.start_link()
Filtrex.Repo.delete_all(Filtrex.SampleModel)

for {title, {d, t}, rating, upvotes} <- data do
  with {:ok, date} <- Date.from_erl(d),
       {:ok, datetime} <- NaiveDateTime.from_erl({d, t}) do
    %Filtrex.SampleModel{
      title: title,
      date_column: date,
      datetime_column: datetime,
      rating: rating,
      upvotes: upvotes
    }
    |> Filtrex.Repo.insert!()
  end
end
