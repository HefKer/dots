-- Ctrl+V in a markdown buffer pastes a clipboard image as a file next to the
-- note, the way the Obsidian app does; any other clipboard content pastes as text.
local in_vault = function()
  return require("config.obsidian").vault(vim.api.nvim_buf_get_name(0)) ~= nil
end

return {
  "HakonHarnes/img-clip.nvim",
  cmd = "PasteImage",
  keys = {
    {
      "<C-v>",
      function()
        if require("img-clip.clipboard").content_is_image() then
          require("img-clip").paste_image()
        else
          vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
        end
      end,
      mode = "i",
      ft = "markdown",
      desc = "Paste Image or Text",
    },
  },
  opts = {
    custom = {
      {
        -- Inside a vault, match Obsidian: its attachment folder, its file
        -- names, and a ![[name]] embed, which it resolves by name alone.
        trigger = in_vault,
        dir_path = function()
          return require("config.obsidian").attachment_dir(vim.api.nvim_buf_get_name(0))
        end,
        file_name = "Pasted image %Y%m%d%H%M%S",
        prompt_for_file_name = false,
        template = "![[$FILE_NAME]]",
      },
    },
  },
}
