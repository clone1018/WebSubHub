# WebSubHub

WebSubHub is a fully compliant WebSub Hub built that you can use to distribute live changes from various publishers. Usage of WebSubHub is very simple with only a single endpoint available at https://websubhub.com/hub.

## Development
You can setup your own development / production environment of WebSubHub easily by grabbing your dependencies, creating your database, and running the server.

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).


### Contributing
1. [Fork it!](http://github.com/clone1018/WebSubHub.tv/fork)
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request


## Testing
WebSubHub includes a comprehensive and very fast test suite, so you should be encouraged to run tests as frequently as possible.

```sh
mix test
```

## Help
If you need help with anything, please feel free to open [a GitHub Issue](https://github.com/clone1018/WebSubHub/issues/new).

## License
WebSubHub is licensed under the [MIT License](LICENSE.md).