export default {

    // Custom plugin to enforce that the subject does not end with punctuation
    plugins: [
        {
            rules: {
                'subject-no-ending-punctuation': (parsed) => {
                    const { subject } = parsed;
                    if (!subject) return [true];

                    // Regex: Checks if the subject ends with any of the punctuation marks
                    const endsWithPunctuation = /[.,;:!?]+$/.test(subject);

                    return [
                        !endsWithPunctuation,
                        `Commit on "${subject}" must not end with punctuation")`
                    ];
                }
            }
        }
    ],

    extends: ['@commitlint/config-conventional'],
    rules: {
        'scope-empty': [2, 'never'], // Scope () is required
        'subject-case': [2, 'always', 'lower-case'], // Subject must be lower-case

        'subject-full-stop': [0, 'never', '.'],
        'subject-no-ending-punctuation': [2, 'always'], // Subject must not end with punctuation
    }
}