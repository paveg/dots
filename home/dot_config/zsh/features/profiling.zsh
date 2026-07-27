# profiling.zsh - profile and time zsh interactive startup
# Provides:     zprofiler, zshtime
zprofiler() { ZSHRC_PROFILE=1 zsh -i -c zprof }
zshtime() { for i in {1..10}; do time zsh -i -c exit; done }
