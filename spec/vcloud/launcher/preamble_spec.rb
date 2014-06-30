require 'spec_helper'

module Vcloud
  module Launcher
    describe Preamble do
      subject { Vcloud::Launcher::Preamble }

      let(:vm_name) { 'test-vm' }
      let(:minimal_vm_config) do
        { bootstrap_config: {
            script_path: 'hello_world.erb',
            vars: { bob: 'Hello', mary: 'Hola' }
          }
        }
      end
      let(:minimal_template) do
        <<-'EOF'
        vars:
        bob: <%= vars[:bob] -%>.
        mary: <%= vars[:mary] %>.
        EOF
      end
      let(:minimal_template_output) do
        <<-EOF
        vars:
        bob: Hello.
        mary: Hola.
        EOF
      end
      let(:minimal_template_lines) { 3 }

      let(:complete_vm_config) do
        { bootstrap_config: {
            script_path: 'hello_world.erb',
            script_post_processor: '/usr/bin/wc -l',
            vars: { bob: 'Hello', mary: 'Hola' }
          },
          extra_disks: [
            { size:  5120, fs_file: '/opt/test_disk1' },
            { size: 10240, fs_file: '/opt/test_disk2' },
          ]
        }
      end

      describe 'public interface' do
        describe 'instance methods' do
          subject { Vcloud::Launcher::Preamble.new(vm_name, minimal_vm_config) }

          it { should respond_to(:generate) }
          it { should respond_to(:interpolated_preamble) }
          it { should respond_to(:output) }

          it { should respond_to(:preamble_vars) }
          it { should respond_to(:script_path) }
        end
      end

      describe '#new' do
        it "accepts complete configuration without error" do
          expect { subject.new(vm_name, minimal_vm_config) }.not_to raise_error
        end

        context "when the preamble template is missing" do
          let(:vm_config) do
            { bootstrap_config: {
                script_post_processor: 'remove_hello.rb',
                vars: { bob: 'hello', mary: 'hola' }
              }
            }
          end

          it "raises a MissingTemplateError" do
            expect { subject.new(vm_name, vm_config) }.
              to raise_error( Vcloud::Launcher::Preamble::MissingTemplateError)
          end
        end

        context "when bootstrap configuration is empty" do
          it "raises a MissingConfigurationError" do
            expect { subject.new(vm_name, {}) }.
              to raise_error(Vcloud::Launcher::Preamble::MissingConfigurationError)
          end
        end

        context "when vars are absent" do
          let(:vm_config) do
            { bootstrap_config: {
                script_path: 'hello_world.erb',
                script_post_processor: 'remove_hello.rb'
              },
            }
          end

          it "raises a MissingConfigurationError" do
            pending("empty vars should be legal, noop template")
            expect { subject.new(vm_name, vm_config ) }.
              to raise_error(Vcloud::Launcher::Preamble::MissingConfigurationError)
          end
        end

        context "when vars are empty" do
          let(:vm_config) do
            { bootstrap_config: {
                script_path: 'hello_world.erb',
                script_post_processor: 'remove_hello.rb',
                vars: {},
              }
            }
          end

          it "raises a MissingConfigurationError" do
            pending("empty vars should be legal, noop template")
            expect { subject.new(vm_name, vm_config ) }.
              to raise_error(Vcloud::Launcher::Preamble::MissingConfigurationError)
          end
        end

        context "extra_disks" do
          subject { Vcloud::Launcher::Preamble.new(vm_name, complete_vm_config) }

          it "merges extra_disks into preamble_vars" do
            expect( subject.preamble_vars ).to have_key(:extra_disks)
          end
        end
      end

      describe ".generate" do
        subject { Vcloud::Launcher::Preamble.new(vm_name, minimal_vm_config) }

        before do
          subject.stub(:load_erb_file).and_return(minimal_template)
        end

        it "invokes .interpolate_preamble_erb_file" do
          subject.should_receive(:interpolate_erb_file)
          subject.generate
        end

        context "interpolating variables" do
          subject { Vcloud::Launcher::Preamble.new(vm_name, minimal_vm_config) }

          context "environment variables" do
            before do
              stub_const('ENV', {'TEST_INTERPOLATED_ENVVAR' => 'test_interpolated_env'})
              subject.stub(:load_erb_file).and_return('env_var: <%= ENV["TEST_INTERPOLATED_ENVVAR"] -%>')
            end

            it "interpolates environment variables into template" do
              expect(subject.generate).to eq 'env_var: test_interpolated_env'
            end
          end

          context "vars hash" do
            before do
              subject.stub(:load_erb_file).and_return(minimal_template)
            end

            it "interpolates vars hash into template" do
              expect(subject.generate).to eq minimal_template_output
            end
          end

          context "vapp_name" do
            before do
              subject.stub(:load_erb_file).and_return('vapp_name: <%= vapp_name -%>')
            end

            it "interpolates vapp_name into template" do
              expect(subject.generate).to eq "vapp_name: #{vm_name}"
            end
          end
        end

        context "when a post processor is supplied" do
          let(:vm_config) do
            { bootstrap_config: {
                script_path: 'hello_world.erb',
                script_post_processor: '/usr/bin/wc -l',
                vars: { bob: 'hello', mary: 'hola' }
              }
            }
          end

          let(:template) do
            <<-EOF
            one
            two
            three
            EOF
          end

          subject { Vcloud::Launcher::Preamble.new(vm_name, vm_config) }

          before do
            subject.stub(:load_erb_file).and_return(template)
          end

          it "invokes .post_process_erb_output" do
            subject.should_receive(:post_process_erb_output)
            subject.generate
          end

          it "returns the post processor output" do
            expect(subject.generate).to match(/^\s*\d+/)
          end
        end

        describe ".interpolated_preamble" do
          subject { Vcloud::Launcher::Preamble.new(vm_name, minimal_vm_config) }

          it "returns the interpolated template" do
            expect(subject.interpolated_preamble).to eq minimal_template_output
          end
        end

        describe ".output" do
          context "when there is no post processor" do
            subject { Vcloud::Launcher::Preamble.new(vm_name, minimal_vm_config) }

            it "returns the interpolated template" do
              expect(subject.output).to eq minimal_template_output
            end
          end

          context "when there is a post processor" do
            subject { Vcloud::Launcher::Preamble.new(vm_name, complete_vm_config) }

            it "returns the post-processed interpolated template" do
              expect(subject.output).to match(/\s*#{minimal_template_lines}/)
            end
          end
        end
      end
    end
  end
end

