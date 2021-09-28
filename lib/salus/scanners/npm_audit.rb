require 'json'
require 'salus/scanners/node_audit'

# NPM Audit scanner integration. Flags known malicious or vulnerable
# dependencies in javascript projects.
# https://medium.com/npm-inc/npm-acquires-lift-security-258e257ef639

module Salus::Scanners
  class NPMAudit < NodeAudit
    AUDIT_COMMAND = 'pnpm audit --json'.freeze

    def should_run?
      true
    end

    def version
      shell_return = run_shell('pnpm --version')
      # stdout looks like "6.14.8\n"
      shell_return.stdout&.strip
    end

    def self.supported_languages
      ['javascript']
    end

    private

    def scan_for_cves
      raw = run_shell(AUDIT_COMMAND).stdout
      json = JSON.parse(raw, symbolize_names: true)

      if json.key?(:error)
        code = json[:error][:code] || '<none>'
        summary = json[:error][:summary] || '<none>'

        message =
          "`#{AUDIT_COMMAND}` failed unexpectedly (error code #{code}):\n" \
          "```\n#{summary}\n```"

        raise message
      end

      report_stdout(json)

      json.fetch(:advisories).values
    end
  end
end
