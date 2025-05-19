; extends

; This injection provides syntax highlighting for strings preceded by a language comment
; Examples:
;   const html = /* html */ `<div>Hello</div>`
;   const sql = /* sql */ "SELECT * FROM users"
;   fetch(/* graphql */ `query { users { id } }`)
;   const config = { query: /* sql */ "SELECT * FROM users" }

[
; ===== Variable Declarations =====

; variable (with template literals/backticks)
; const html = /* html */ `<html>`
; const sql = /* sql */ `SELECT * FROM foo`
(variable_declarator
  (comment) @injection.language .
  (template_string
    (string_fragment) @injection.content)
)

; variable (with single/double quotes)
; const sql = /* sql */ "SELECT * FROM foo"
; let html = /* html */ 'text'
(variable_declarator
  (comment) @injection.language .
  (string (string_fragment) @injection.content)
)

; ===== Assignment Expressions =====

; assignment (with template literals/backticks)
; elem.innerHTML = /* html */ `<div></div>`
(assignment_expression
  (comment) @injection.language .
  right: (
    (template_string
      (string_fragment) @injection.content)
  )
)

; assignment (with single/double quotes)
; elem.innerHTML = /* html */ "<div></div>"
(assignment_expression
  (comment) @injection.language .
  right: (
    (string (string_fragment) @injection.content)
  )
)

; ===== Function Arguments =====

; argument (with template literals/backticks)
; foo(/* html */ `<span>`)
; query(/* sql */ `SELECT * FROM foo`)
(call_expression
  arguments:
  [
    (arguments
      (comment) @injection.language .
      (template_string
        (string_fragment) @injection.content)
    )
  ]
)

; argument (with single/double quotes)
; foo(/* html */ "<span>")
; query(/* sql */ 'SELECT * FROM foo')
(call_expression
  arguments:
  [
    (arguments
      (comment) @injection.language .
      (string (string_fragment) @injection.content)
    )
  ]
)

; ===== Object Properties =====

; object property (with template literals/backticks)
; const obj = { template: /* html */ `<div></div>` }
(pair
  (comment) @injection.language .
  value: (
    (template_string
      (string_fragment) @injection.content)
  )
)

; object property (with single/double quotes)
; const obj = { query: /* sql */ "SELECT * FROM users" }
(pair
  (comment) @injection.language .
  value: (
    (string (string_fragment) @injection.content)
  )
)

; ===== Array Elements =====

; array element (with template literals/backticks)
; const queries = [/* sql */ `SELECT * FROM users`]
(array
  (comment) @injection.language .
  (template_string
    (string_fragment) @injection.content)
)

; array element (with single/double quotes)
; const templates = [/* html */ "<div></div>"]
(array
  (comment) @injection.language .
  (string (string_fragment) @injection.content)
)

(#lua-match? @injection.language "/%*%s*(%w+)%s*%*/")
(#gsub! @injection.language "/%*%s*([%w%p]+)%s*%*/" "%1")
]
