local M = {}
local ns = vim.api.nvim_create_namespace("gvhi")
function M.ansi_highlight()
  for i = 1, vim.fn.line('$') do
    local l = vim.fn.getline(i)
    local prev_hi = ''
    local prev_idx = ''
    local hi_list = {}

    local s = 0
    while true do
      local m, s, e = unpack(vim.fn.matchstrpos(l, '\\e\\[[0-9;]*[mK]', s))
      if #m == 0 then
        break
      end
      if s == 0 then
        l = l:sub(e + 1)
      else
        l = l:sub(1, s) .. l:sub(e + 1)
      end

      local cur_hi = ansi_hi_group(m)
      if prev_hi == cur_hi then
        goto continue
      end

      if #prev_hi > 0 then
        table.insert(hi_list, {prev_hi, prev_idx, s})
      end

      prev_hi = cur_hi
      prev_idx = s
      ::continue::
    end

    vim.fn.setline(i, l)

    for _, v in ipairs(hi_list) do
      local prefix, s, e = v[1], v[2], v[3]
      vim.highlight.range(vim.fn.bufnr('%'), ns, 'gvAnsi'..prefix, {i-1, s}, {i-1,e})
    end
    
  end
end

function ansi_hi_group(ansi)
  return vim.fn.matchstr(ansi, '\\d\\zem')
end



return M
