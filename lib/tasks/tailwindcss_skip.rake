# Skip the Tailwind CSS build when TAILWINDCSS_SKIP_BUILD is set.
# This is needed because the tailwindcss binary produces broken output
# under QEMU (amd64 emulation on ARM hosts). In Docker, we rely on the
# pre-built tailwind.css checked into app/assets/builds/.
if ENV["TAILWINDCSS_SKIP_BUILD"].present?
  Rake::Task["tailwindcss:build"].clear
  namespace :tailwindcss do
    task build: :environment do
      puts "Skipping tailwindcss:build (TAILWINDCSS_SKIP_BUILD is set)"
    end
  end
end
