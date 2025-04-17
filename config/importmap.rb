# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "word_counter", to: "word_counter.js"
pin "timer", to: "timer.js"
pin "feedback_poller", to: "feedback_poller.js"
pin "chartkick", to: "chartkick.js"
pin "Chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.9/dist/chart.umd.js"
pin "date-fns", to: "https://cdn.jsdelivr.net/npm/date-fns@3.6.0/cdn.min.js"  # date-fns (今回手動指定)
pin "chartjs-adapter-date-fns", to: "https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.bundle.min.js" # adapter (今回手動指定)
pin "@kurkle/color", to: "@kurkle--color.js"