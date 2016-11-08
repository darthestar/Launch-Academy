require "sinatra"
require "pg"
require 'pry'

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end


get '/actors' do
  get_ordered_actors_names
  erb:index
end

get '/actors/:id' do
  @actor_id = (params[:id]).to_i
  @actor_movies_and_characters = db_connection { |conn|
    conn.exec_params("SELECT cast_members.character, movies.title, actors.name, movies.id
    FROM cast_members
    left OUTER Join movies ON (cast_members.movie_id = movies.id)
    left outer Join actors on (cast_members.actor_id = actors.id)
    WHERE cast_members.actor_id = $1",[@actor_id]) }
  erb:show
end

get '/movies' do
  get_movies
  erb:movies
end

get '/movies/:id' do
  @movie_id = (params[:id]).to_i
  @movies_info = db_connection { |conn| conn.exec_params("SELECT year, rating, genre_id, studio_id
                        FROM movies
                        full outer join genres on movies.genre_id = genres.id
                        full outer join on movies.studio_id = studios.id
                        where movies.id = $1", [@movie_id]) }
  erb:movies_show
end

def get_ordered_actors_names
  @actors = db_connection { |conn| conn.exec_params("SELECT name, actors.id FROM actors
    ORDER BY name") }
end

def get_movies
  @movies = db_connection { |conn| conn.exec_params("SELECT title, year, rating, genre_id, studio_id, movies.id FROM movies
    full outer join genres on movies.genre_id = genres.id
    full outer join studios on movies.studio_id = studios.id
    ORDER BY title") }
end
