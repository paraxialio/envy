# Envy

## For Educational Purposes Only

This project is intended to demonstrate how credential stuffing works against a Phoenix app. Do not use this software against a real website without explicit permission from the owner.

## Use

```
envy % mix run do_ato.exs 
Envy Account Takeover Tool v1.0
For educational and authorizing testing purposes only. 

Example usage, default rate limit (60 requests per minute):
mix run do_ato.exs credentials.txt

Example usage, custom rate limit (100 requests per minute): 
mix run do_ato.exs credentials.txt 100
```
