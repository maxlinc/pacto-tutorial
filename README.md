# Pacto Getting Started Tutorial

This tutorial will guide you through Pacto's basic features.  Pacto is a framework for Integration Contract Testing.  Our tutorial will use the GitHub API so you can easily compare our approach with related techniques in ThoughtBot's [How to Stub External Services in Tests](http://robots.thoughtbot.com/how-to-stub-external-services-in-tests/).

However, keep in mind that Pacto is not just a stub provider, it is an [Integration Contract Testing](http://martinfowler.com/bliki/IntegrationContractTest.html) framework that you can use to compliment other stubbing solutions.  In fact, in this tutorial you will:

* Use Pacto to generate a Contract
* Use that Contract to validate:
  * The live service
  * A raw WebMock stub
  * A VCR [self-initializing fake](http://martinfowler.com/bliki/SelfInitializingFake.html)
  * A fake implemented via Sinatra
* Finally, you will use the Contract to stub via Pacto

Unfortunately, we cannot cover Pacto's flexible features that enable Consumer-Driven Contracts, Documentation-Driven Contracts, polyglot testing, or other workflows in this tutorial.  If you're interested in advanced techniques, please browse the full documentation and join our our mailing list.

## Setting up the tutorial

We're going to start with something similar to the ThoughtBot guide.  We've made a few minor enhancements over what was in their post, though.  We setup the spec_helper and a Rakefile to make it easier to switch between the stub providers.

You can start the tutorial by cloning our repo:

```sh
$ git clone git@github.com:thoughtworks/pacto-tutorial.git
$ cd pacto-tutorial
```

Then make sure you're able to see our rake tasks:

```sh
$ bundle install
$ bundle exec rake -vT
...
rake test:all      # Run the tests against the live service and then against each stub provider
rake test:live     # Run the tests against the real services
rake test:pacto    # Run tests while stubbing with pacto
rake test:sinatra  # Run tests while stubbing with sinatra
rake test:vcr      # Run tests while stubbing with vcr
rake test:webmock  # Run tests while stubbing with webmock
```

If everything is working properly, then you will find that the live tests, plus stubbing with webmock, vcr, and sinatra all work when you run `bundle exec rake test:all`.  It will fail on Pacto - don't worry!  We'll get Pacto setup soon enough.

## A closer look

Let's take a look at our starting point before we make any changes.  The most important thing is `spec/spec_helper.rb`.  We've made a couple changes from the ThoughtBot post.

First you'll see a brief section to load and configure Pacto:

```ruby
require 'pacto'
require 'pacto/rspec'

Pacto.configure do |config|
  config.contracts_path = 'contracts'
end
```

That's all the configuration you normally need to use Pacto in an RSpec suite.  It loads Pacto, loads Pacto's rspec matchers, and then tells Pacto that contracts will be stored in the `contracts/` directory.

The rest of the `spec_helper.rb` just contains tricks to quickly switch back between different stub providers and ways of using Pacto so we can quickly demo a few features.  Normally, you would just put the necessary configuration right in you `spec_helper.rb`, rather than dynamically changing the configuration.

The first part controls the "PACTO_MODE":

```ruby
pacto_mode = ENV['PACTO_MODE']
require "pacto_modes/#{pacto_mode}" if pacto_mode
```

We haven't added any modes yet, but we'll add two by the end of the tutorial: generate and validate.

We have a similar trick to select a stub provider:

```ruby
stub_provider = ENV['STUB_WITH']
if stub_provider
  puts "Stubbing with: #{stub_provider}"
  require "stub_providers/#{stub_provider}"
else
  puts "Running live tests"
  WebMock.allow_net_connect!
end
```

The available stub providers are webmock, vcr and sinatra.  We'll be adding pacto.  If you don't specify a stub provider, the tests run against the live, production services.  The configuration for each stub provider is basically the same as the ThoughtBot post.  If you want to review, the code is in `spec/stub_providers/`.

## Generating a Contract

We need a Contract to start using Pacto.  We'll get one the easy way: we'll let Pacto generate it for us.  We just need to put Pacto into generate mode.

Create `spec/pacto_modes/generate.rb` and add:

```ruby
Pacto.generate!
```

That's it!  Pacto will now generate contracts for requests it receives.

In order to generate Contracts from the live service, run:

```sh
PACTO_MODE=generate bundle exec rake test:live
```

Once the test finishes, you should have a new file: `contracts/api.github.com/repos/thoughtbot/factory_girl/contributors.json`.  We'll take a closer look at the file later, but first let's see how we can use the Contract.

## Adding Contract validation

We can now put Pacto into Validation mode.  This will cause it to start validating each request it sees against any matching Contracts.  First, let's add our validation mode.  Create `spec/pacto_modes/validate.rb` with:

```ruby
Pacto.validate!
hosts = Dir["#{Pacto.configuration.contracts_path}/*"].each do |host|
  host = File.basename host
  Pacto.load_all host, "https://#{host}", :default
end
Pacto.use :default
```

This tells Pacto to turn on validation, to load each of the contracts with the tag :default, and then to use those contracts by enabling contracts with the tag :default.

Now, let's make a few additions to `spec/external_request_spec.rb`.

```diff
     response = Net::HTTP.get(uri)

     expect(response).to be_an_instance_of(String)
+    expect(Pacto).to have_validated(:get, 'https://api.github.com/repos/thoughtbot/factory_girl/contributors')
+    expect(Pacto).to_not have_failed_validations
+    expect(Pacto).to_not have_unmatched_requests
   end
 end
 ```

What do these three new assertions do?  The first one not only makes sure we received a request (WebMock can do that) - it also makes sure that it was validated against a Contract.  If we want to be a little more strict, we can specify which contract we expected:

```ruby
expect(Pacto).to have_validated(:get, 'https://api.github.com/repos/thoughtbot/factory_girl/contributors')
  .against_contract /contributors.json/
```

### Running the validations

If you run:

```sh
$ PACTO_MODE=validate bundle exec rake test:live
$ PACTO_MODE=validate bundle exec rake test:vcr
```

You should see they both pass.  Now try:

```sh
$ PACTO_MODE=validate brake test:webmock
$ PACTO_MODE=validate brake test:sinatra
```

You'll see some errors:

```sh
  1) External request queries FactoryGirl contributors on Github
     Failure/Error: expect(Pacto).to have_validated(:get, 'https://api.github.com/repos/thoughtbot/factory_girl/contributors')
       expected Pacto to have validated GET https://api.github.com/repos/thoughtbot/factory_girl/contributors
         but validation errors were found:
Missing expected response header: Content-Type
           Missing expected response header: Status
           Missing expected response header: Cache-Control
           Missing expected response header: Etag
           Missing expected response header: Vary
           Missing expected response header: Access-Control-Allow-Credentials
           Missing expected response header: Access-Control-Expose-Headers
           Missing expected response header: Access-Control-Allow-Origin
```

Ah ha!  The real service sends Vary and Cache-Control headers in the response, but the WebMock and Sinatra stubs do not!  This may seem trivial, and while Pacto tries to figure out which headers matter when you generate a contract, it isn't psychic.  On the other hand, Vary and Cache-Control affect behavior of proxies and clients in important but subtle ways, so testing with realistic values can help avoid bugs.  In fact the Vary header tells proxies what request information is important, and Pacto itself uses that information to decide which request headers to record during generation.

# A closer look at the Contract

