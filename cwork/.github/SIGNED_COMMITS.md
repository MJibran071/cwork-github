# Signed Commits Guide for Cwork Developers

## Why Signed Commits?
Signed commits provide cryptographic verification that commits were created by a trusted developer. This prevents unauthorized commits and ensures the integrity of the codebase.

## Requirements
- Git installed on your local machine
- GPG (GNU Privacy Guard) installed
- GitHub account with verified email

## Step 1: Install GPG

### macOS
```bash
brew install gnupg
```

### Ubuntu/Debian
```bash
sudo apt-get install gnupg
```

### Windows
Download from [GPG4Win](https://www.gpg4win.org/)

## Step 2: Generate GPG Key

1. Generate a new GPG key:
```bash
gpg --full-generate-key
```

2. Select key type: `RSA and RSA` (default)
3. Key size: `4096`
4. Key expiration: `1y` (recommended for security)
5. Enter your name and email (must match your GitHub email)
6. Protect with a strong passphrase

## Step 3: List Your GPG Keys

```bash
gpg --list-secret-keys --keyid-format LONG
```

Copy the key ID (after `sec rsa4096/`), it will look like: `3AA5C34371567BD2`

## Step 4: Export GPG Public Key

```bash
gpg --armor --export YOUR_KEY_ID
# Example: gpg --armor --export 3AA5C34371567BD2
```

Copy the entire output including `-----BEGIN PGP PUBLIC KEY BLOCK-----` and `-----END PGP PUBLIC KEY BLOCK-----`

## Step 5: Add GPG Key to GitHub

1. Go to GitHub Settings -> SSH and GPG keys
2. Click "New GPG key"
3. Paste your public key
4. Click "Add GPG key"

## Step 6: Configure Git to Use GPG

```bash
# Tell Git about your signing key
git config --global user.signingkey YOUR_KEY_ID

# Enable commit signing globally
git config --global commit.gpgsign true

# Optional: Set GPG program path if needed
# git config --global gpg.program $(which gpg)
```

## Step 7: Test Signed Commits

```bash
# Create a test commit
echo "test signed commit" > test.txt
git add test.txt
git commit -S -m "Test signed commit"

# Verify the commit signature
git log --show-signature -1
```

## Step 8: Troubleshooting

### Common Issues

**GPG agent not running:**
```bash
# Start GPG agent
gpgconf --launch gpg-agent
```

**Passphrase prompt not showing:**
```bash
# Set GPG TTY
export GPG_TTY=$(tty)
```

**Git not finding GPG:**
```bash
# Check GPG path
which gpg
# Set explicit path in Git config
git config --global gpg.program /usr/local/bin/gpg
```

### macOS Specific

If using GPG Suite:
```bash
# Ensure GPG tools are in PATH
export PATH=/usr/local/bin:$PATH
git config --global gpg.program /usr/local/bin/gpg
```

### Windows Specific

If using Git Bash:
```bash
# Set GPG program path
git config --global gpg.program "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
```

## Step 9: Verify GitHub Recognition

1. Push your signed commit to GitHub
2. Check the commit on GitHub - it should show "Verified" badge

## Step 10: Repository Enforcement

Once all developers have set up signed commits, repository administrators should:

1. Enable branch protection rules requiring signed commits
2. Configure GitHub to reject unsigned commits to protected branches
3. Regularly audit commit signatures

## Security Best Practices

1. **Key Rotation**: Rotate GPG keys annually or when compromised
2. **Backup Keys**: Securely backup your GPG private key and passphrase
3. **Revocation**: Create and store a revocation certificate for emergency use
4. **Passphrase**: Use a strong, unique passphrase for your GPG key

## Creating Revocation Certificate

```bash
gpg --output revoke.asc --gen-revoke YOUR_KEY_ID
```

Store `revoke.asc` in a secure location - this allows you to revoke your key if compromised.

## Additional Resources

- [GitHub Docs: Signing Commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)
- [GPG Documentation](https://www.gnupg.org/documentation/)
- [Pro Git Book: Signing Your Work](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)

## Support

If you encounter issues with signed commits, contact the security team or refer to the infrastructure documentation.