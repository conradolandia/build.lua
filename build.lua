#!/usr/bin/env lua

-- [[ Customization ]]
--
-- Strings used all around
local space = " "
local intro = "Processing the file "
local separator = "\n"
local error_message = space .. "failed to complete"
local success_message = space .. "completed successfully"

-- Build tree
local base_folder = "/context/third/pauta/"
local build_folder = "tex" .. base_folder
local docs_folder = "doc" .. base_folder

-- Generating documentation with Pandoc
local docs_command = "pandoc"

-- Processing with LMTX
local build_command = "/home/andi/Apps/lmtx/tex/texmf-linux-64/bin/context"
local build_path = "--path=" .. docs_folder .. "," .. build_folder

-- Do we show the build log in the terminal?
local show_log = false

-- Do we keek those logs in the root folder?
local delete_logs = true

-- Build modes for LMTX
local build_modes = {
    h = "--mode=letter:h",
    v = "--mode=letter:v"
}

-- Create full options string for the build command with optional mode
local function create_options(mode)
    local build_options = {}
    if show_log then
        table.insert(build_options, "--noconsole")
    end
    if delete_logs then
        table.insert(build_options, "--purgeall")
    end

    table.insert(build_options, build_path)

    return table.concat(build_options, space) .. space .. mode
end

-- Tasks to execute and options
local tasks = {{
    name = "Build documentation from README.md",
    command = docs_command,
    options = "--from=markdown --to=context+ntb --wrap=none --top-level-division=chapter --section-divs",
    input = "README.md",
    after = "-o",
    output = docs_folder .. "README.tex"
  }, {
    name = "Typeset example",
    command = build_command,
    options = create_options(build_modes.h),
    input = docs_folder .. "pauta-example.tex",
    postprocess = "mv pauta-example.pdf " .. docs_folder
  }, {
    name = "Typeset documentation",
    command = build_command,
    options = create_options(build_modes.v),
    input = docs_folder .. "pauta.tex",
    postprocess = "mv pauta.pdf " .. docs_folder
}}

-- [[ Internal functions ]]

-- Function to build a task
local function execute(task, show_output)
    print("Executing [ " .. task.name .. " ]")

    local command = task.command

    if task.options then
        command = command .. space .. task.options
    end

    if task.input then
        command = command .. space .. task.input
    end

    if task.after then
        command = command .. space .. task.after
    end

    if task.output then
        command = command .. space .. task.output
    end

    print("Calling: " .. command)

    local handle = io.popen(command)
    local output = handle:read("*a")

    if show_output then
      print(output)
    end

    local message

    if handle then
        message = success_message
    end

    print(intro .. task.input .. message)

    if task.postprocess ~= nil then
      local success, tag, code = os.execute(task.postprocess)
      if success then
        print("Postprocessing: " .. task.postprocess .. separator)
      end
    else
      print(separator)
    end
end

-- Build each task in the list
for key, task in ipairs(tasks) do
    io.write("[" .. key .. "/" .. #tasks .. "] -> ")
    execute(task, show_log)
end
