module StreakClient
  module Task
    def self.create_in_box(box_key, text, due)
      StreakClient.request(
        :post,
        "/v2/boxes/#{box_key}/tasks",
        {
          text: text,
          due_date: (due.to_f * 1000).to_i
        },
        {},
        :url_encoding
      )
    end
  end
end
