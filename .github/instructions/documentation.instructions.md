---
description: 'Create concise documentation that is easy to understand and follows critical linting requirements.'
applyTo: '**/*.md'
---

This chat mode is designed to reduce the amount of repetitive or boilerplate content in documentation.

Documentation should:

- Quickly establish the purpose
- Provide clear mechanism to get started, using visuals where helpful
- Avoid unnecessary repetition of standard sections, such as "Introduction", "Scope", unless they contain unique or critical information.
- Use placeholders or external sources, rather than duplicating content.
- Keep it brief so that users do not feel overwhelmed by too much text.
- Break things into smaller sections or bullet points for easier scanning.
- Focus on the flow of the activity, what needs to be done next, rather than lengthy comparisons and summaries.
- Reference sources at the end using URLs.  Check these URLs are valid.
- Avoid excessive use of emojis because it looks unprofessional.
- If you make a statement such as "comfortable with X", or "accept limitations of Y", provide a reference to primary documentation in the references so that users can validate the decision.
- Whilst remaining succinct, be careful not to omit critical information that could lead to misconfigurations.

## Markdown linting tips:

- **Important**: Be sure to be aware of all linting tips **before** writing markdown - it is easier to get this right when authoring rather than fixing later line by line.
- Make sure to add a line break before a list or codeblock.
- Don't use emphasis as a heading.  Only use emphasis for highlighting key terms in sentences.
- Fenced code blocks should specify the language for proper syntax highlighting.
- Linting issues are not minor, they should be fixed, you should not leave "Problems" in the VSCode because it distracts users and makes it harder to find real issues.
- If you believe an exception to linting rules is necessary, then use markdownlint metadata to mark this, e.g.,

```markdown
<!-- markdownlint-disable-next-line MD033 -->
<div>Some HTML content</div>
```

## Corrections

If directed by a user to fix something, verify with a check against primary sources, and then include a link in the References section.

You don't need to reference changes that are already covered by existing sources or are widely known.

## Use of relative links

When referencing other documentation within the same repository, use relative links to aid navigation and ensure portability across different environments.