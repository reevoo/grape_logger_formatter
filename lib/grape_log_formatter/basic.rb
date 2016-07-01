module GrapeLogFormatter
  class Basic
    def call(severity, datetime, _, data)
      "[#{datetime}] #{severity} -- #{format(data)}\n\n"
    end

    private

    def format(data)
      case data
      when ::String
        data
      when ::Exception
        format_exception(data)
      when ::Hash
        format_common_request(data)
      else
        data.inspect
      end
    end

    def format_common_request(data)
      data = data_with_defaults(data)

      str = []
      str.push sprintf("%{method} %{status} %{tags} %{path}", data)
      str.push sprintf("Params: %{params}", params: JSON.dump(data[:params])) if data[:params].present?
      str.push sprintf("PID: %{pid} | IP: %{ip} | Total: %{total} DB: %{db} View: %{view}", data)
      str.push format_exception(data[:exception]) if data[:exception].present?

      str.map(&:strip).join("\n")
    end

    def data_with_defaults(data)
      env = data[:env] || {}
      time = data[:time] || { total: "-", db: "-", view: "-" }
      data.reverse_merge(
        method: nil,
        status: nil,
        tags: nil,
        path: env["PATH_INFO"],
        total: time[:total],
        db: time[:db],
        view: time[:view],
        ip: env["REMOTE_ADDR"] || "-",
        exception: nil,
        params: env["rack.routing_args"].try(:except, :route_info),
        pid: $PROCESS_ID,
      )
    end

    def format_exception(exception)
      backtrace_array = (exception.backtrace || []).map { |line| "\t#{line}" }
      "#{exception.message}\n#{backtrace_array.join("\n")}"
    end
  end
end
