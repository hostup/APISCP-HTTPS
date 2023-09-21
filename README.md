# Check SSLv2 Domains Script made for https://apiscp.com

This script examines SSL certificates located in the `/home/virtual/*/fst/etc/httpd/conf/ssl.crt/` directory. It extracts domain names from the 'Subject Alternative Name' section of each certificate. For wildcard domains (e.g., `*.domain.tld`), it considers the equivalent `www.domain.tld`. The script then checks if the domain's IP is not within Cloudflare's IP range. Valid domains meeting the criteria are saved to `/etc/httpd/conf.d/ssl_domains.txt`.

## Requirements

- Bash shell environment
- `openssl` tool for examining SSL certificates
- `dig` command for DNS lookups (usually part of the `bind-utils` package on many Linux distributions)

## Usage

1. Ensure the script is executable:

```bash
chmod +x checksslv2.sh
```

2. Run the script:

```bash
./checksslv2.sh
```

3. Review the results in `/etc/httpd/conf.d/ssl_domains.txt`.

## Notes

- The current script is tailored to directories and file structures as provided. You might need to adjust paths or other parameters to fit your setup.
- IP ranges for Cloudflare are hard-coded in the script. These might change over time, so consider updating them if needed.

## Contributions

If you find any bugs or have improvements in mind, feel free to open an issue or submit a pull request.

## License

[MIT License](LICENSE) - [More info](https://opensource.org/licenses/MIT)
