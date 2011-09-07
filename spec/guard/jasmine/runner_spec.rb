require 'spec_helper'

describe Guard::Jasmine::Runner do

  let(:runner) { Guard::Jasmine::Runner }

  let(:defaults) do
    {
        :jasmine_url   => 'http://localhost:3000/jasmine',
        :phantomjs_bin => '/usr/local/bin/phantomjs',
        :notification  => true,
        :hide_success  => false
    }
  end

  let(:error_response) do
    <<-JSON
    {
      "error": "Cannot request Jasmine specs"
    }
    JSON
  end

  let(:failure_response) do
    <<-JSON
    {
      "suites": [
        {
          "description": "FailureTest",
          "filter": "?spec=FailureTest",
          "specs": [
            {
              "description": "FailureTest tests something.",
              "error_message": "Expected undefined to be defined."
            }
          ]
        }
      ],
      "stats": {
        "specs": 4,
        "failures": 1,
        "time": 0.007
      }
    }
    JSON
  end

  let(:success_response) do
    <<-JSON
    {
      "suites": [],
      "stats": {
        "specs": 4,
        "failures": 0,
        "time": 0.009
      }
    }
    JSON
  end

  before do
    ::Guard::Jasmine::Formatter.stub(:notify)
  end

  describe '#run' do
    context "when passed an empty paths list" do
      it "returns false" do
        runner.run([]).should be_false
      end
    end

    context "when passed the spec directory" do
      it 'requests all jasmine specs from the server' do
        IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine").and_return StringIO.new(error_response)
        runner.run(['spec/javascripts'], { :notification => false }.merge(defaults))
      end
    end

    context "for an erroneous Jasmine spec" do
      it 'requests the jasmine specs from the server' do
        File.should_receive(:foreach).with('spec/javascripts/a.js.coffee').and_yield 'describe "ErrorTest", ->'
        IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=ErrorTest").and_return StringIO.new(error_response)
        runner.run(['spec/javascripts/a.js.coffee'], { :notification => false }.merge(defaults))
      end

      it 'shows the error in the console' do
        File.should_receive(:foreach).with('spec/javascripts/a.js.coffee').and_yield 'describe "ErrorTest", ->'
        IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=ErrorTest").and_return StringIO.new(error_response)

        ::Guard::Jasmine::Formatter.should_receive(:error).with(
            "An error occurred: Cannot request Jasmine specs"
        )

        runner.run(['spec/javascripts/a.js.coffee'], defaults.merge({ :notification => false }))
      end

      context 'with notifications' do
        it 'shows an error notification' do
          File.should_receive(:foreach).with('spec/javascripts/a.js.coffee').and_yield 'describe "ErrorTest", ->'
          IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=ErrorTest").and_return StringIO.new(error_response)

          ::Guard::Jasmine::Formatter.should_receive(:notify).with(
              "An error occurred: Cannot request Jasmine specs",
              :title    => 'Jasmine error',
              :image    => :failed,
              :priority => 2
          )

          runner.run(['spec/javascripts/a.js.coffee'], defaults.merge({ :notification => true }))
        end
      end

      context 'without notifications' do
        it 'does not shows an error notification' do
          File.should_receive(:foreach).with('spec/javascripts/a.js.coffee').and_yield 'describe "ErrorTest", ->'
          IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=ErrorTest").and_return StringIO.new(error_response)

          ::Guard::Jasmine::Formatter.should_not_receive(:notify)

          runner.run(['spec/javascripts/a.js.coffee'], defaults.merge({ :notification => false }))
        end
      end
    end

    context "for a failing Jasmine spec" do
      it 'requests the jasmine specs from the server' do
        File.should_receive(:foreach).with('spec/javascripts/x/b.js.coffee').and_yield 'describe "FailureTest", ->'
        IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=FailureTest").and_return StringIO.new(failure_response)
        runner.run(['spec/javascripts/x/b.js.coffee'], { :notification => false }.merge(defaults))
      end

      it 'shows the failure in the console' do
        File.should_receive(:foreach).with('spec/javascripts/x/b.js.coffee').and_yield 'describe "FailureTest", ->'
        IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=FailureTest").and_return StringIO.new(failure_response)

        ::Guard::Jasmine::Formatter.should_receive(:error).with(
            "Spec 'FailureTest tests something.' failed with 'Expected undefined to be defined.'!\nJasmine ran 4 specs, 1 failure in 0.007s."
        )

        runner.run(['spec/javascripts/x/b.js.coffee'], { :notification => false }.merge(defaults))
      end

      context 'with notifications' do
        it 'shows a failure notification' do
          File.should_receive(:foreach).with('spec/javascripts/x/b.js.coffee').and_yield 'describe "FailureTest", ->'
          IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=FailureTest").and_return StringIO.new(failure_response)

          ::Guard::Jasmine::Formatter.should_receive(:notify).with(
              "Spec 'FailureTest tests something.' failed with 'Expected undefined to be defined.'!\nJasmine ran 4 specs, 1 failure in 0.007s.",
              :title    => 'Jasmine results',
              :image    => :failed,
              :priority => 2
          )

          runner.run(['spec/javascripts/x/b.js.coffee'], defaults.merge({ :notification => true }))
        end
      end

      context 'without notifications' do
        it 'does not show a failure notification' do
          File.should_receive(:foreach).with('spec/javascripts/x/b.js.coffee').and_yield 'describe "FailureTest", ->'
          IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=FailureTest").and_return StringIO.new(failure_response)

          ::Guard::Jasmine::Formatter.should_not_receive(:notify)

          runner.run(['spec/javascripts/x/b.js.coffee'], defaults.merge({ :notification => false }))
        end
      end
    end

    context "for a successful Jasmine spec" do
      it 'requests the jasmine specs from the server' do
        File.should_receive(:foreach).with('spec/javascripts/t.js').and_yield 'describe("SuccessTest", function() {'
        IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=SuccessTest").and_return StringIO.new(success_response)
        runner.run(['spec/javascripts/t.js'], defaults.merge({ :notification => false }))
      end

      it 'shows the success in the console' do
        File.should_receive(:foreach).with('spec/javascripts/t.js').and_yield 'describe("SuccessTest", function() {'
        IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=SuccessTest").and_return StringIO.new(success_response)

        ::Guard::Jasmine::Formatter.should_receive(:success).with(
            "Jasmine ran 4 specs, 0 failures in 0.009s."
        )

        runner.run(['spec/javascripts/t.js'], defaults.merge({ :notification => false }))
      end

      context 'with notifications' do
        it 'shows a success notification' do
          File.should_receive(:foreach).with('spec/javascripts/t.js').and_yield 'describe("SuccessTest", function() {'
          IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=SuccessTest").and_return StringIO.new(success_response)

          ::Guard::Jasmine::Formatter.should_receive(:notify).with(
              "Jasmine ran 4 specs, 0 failures in 0.009s.",
              :title    => 'Jasmine results'
          )

          runner.run(['spec/javascripts/t.js'], defaults.merge({ :notification => true }))
        end

        context 'with hide success notifications' do
          it 'des not shows a success notification' do
            File.should_receive(:foreach).with('spec/javascripts/t.js').and_yield 'describe("SuccessTest", function() {'
            IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=SuccessTest").and_return StringIO.new(success_response)

            ::Guard::Jasmine::Formatter.should_not_receive(:notify)

            runner.run(['spec/javascripts/t.js'], defaults.merge({ :notification => true, :hide_success => true }))
          end
        end
      end

      context 'without notifications' do
        it 'does not shows a success notification' do
          File.should_receive(:foreach).with('spec/javascripts/t.js').and_yield 'describe("SuccessTest", function() {'
          IO.should_receive(:popen).with("/usr/local/bin/phantomjs #{ @project_path }/lib/guard/jasmine/phantomjs/run-jasmine.coffee http://localhost:3000/jasmine?spec=SuccessTest").and_return StringIO.new(success_response)

          ::Guard::Jasmine::Formatter.should_not_receive(:notify)

          runner.run(['spec/javascripts/t.js'], defaults.merge({ :notification => false }))
        end
      end
    end

  end

end
