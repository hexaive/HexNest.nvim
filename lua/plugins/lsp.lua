-- 🔑 키 매핑 유틸 불러오기
local keyMapper = require("utils.KeyMapper").mapKey

-- 🔔 진단 메시지(경고/에러) 토글 상태 변수
local showWarnings = true

-- 🔁 경고 메시지를 켜고 끄는 함수 (전역 등록)
function _G.toggleWarnings()
  showWarnings = not showWarnings

  if showWarnings then
    -- 경고 메시지를 다시 보여줌
    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      underline = true,
    })
    print("🔔 Warnings shown")
  else
    -- 에러만 보이도록 설정 (경고는 숨김)
    vim.diagnostic.config({
      virtual_text = { severity = { min = vim.diagnostic.severity.ERROR } },
      signs = { severity = { min = vim.diagnostic.severity.ERROR } },
      underline = { severity = { min = vim.diagnostic.severity.ERROR } },
    })
    print("🔕 Warnings hidden")
  end
end

-- 💡 경고 토글 단축키를 전역으로 등록 (LSP랑 무관하게 항상 사용 가능)
keyMapper("<leader>tw", "<cmd>lua toggleWarnings()<CR>")

-- 🧠 LSP 서버가 버퍼에 연결될 때 실행되는 함수
local function on_attach(client, bufnr)
  print("✅ LSP attached:", client.name) -- 디버깅용 출력

  local opts = { buffer = bufnr }

  -- 🧭 LSP 기능 단축키 설정
  keyMapper("K", vim.lsp.buf.hover, opts)                -- 문서 호버
  keyMapper("gd", vim.lsp.buf.definition, opts)          -- 정의로 이동
  keyMapper("<leader>ca", vim.lsp.buf.code_action, opts) -- 코드 액션

  -- 💾 저장할 때 자동 포맷 실행
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ async = false })
      end,
    })
  end
end

-- 🔧 LSP 관련 플러그인 설정들 리턴
return {
  -- 📦 Mason: LSP 서버 설치 관리자
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- 🧩 Mason-lspconfig: LSP 서버 자동 설치
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",    -- Lua 언어 서버
          "ts_ls",     -- TypeScript/JavaScript 언어 서버
          "remark_ls", -- Markdown 관련 서버
          "clangd",    -- C/C++
          "pyright",   -- Python
        },
      })
    end,
  },

  -- 🧠 nvim-lspconfig: 실제 LSP 서버 설정
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")

      local servers = {
        "lua_ls",
        "ts_ls",
        "remark_ls",
        "clangd",
        "pyright",
      }

      -- 모든 서버에 공통으로 on_attach 적용
      for _, server in ipairs(servers) do
        lspconfig[server].setup({
          on_attach = on_attach,
        })
      end

      -- 🛠️ 진단 메시지 기본 설정 (에러, 경고, 힌트 등 표시 방식)
      vim.diagnostic.config({
        virtual_text = {
          prefix = "●", -- 메시지 앞에 ● 표시
          severity = { min = vim.diagnostic.severity.HINT }, -- 최소 힌트부터 표시
        },
        signs = true, -- 왼쪽 사인 표시
        underline = true, -- 밑줄 표시
        update_in_insert = false, -- 입력 중 업데이트 안 함
        severity_sort = true, -- 심각도 기준 정렬
      })
    end,
  },

  -- 🔋 fidget.nvim: LSP 로딩 상태 표시
  {
    "j-hui/fidget.nvim",
    opts = {}, -- 기본 설정 사용
  },

  -- 🎨 lsp-colors.nvim: LSP 진단 메시지 색 보완
  {
    "folke/lsp-colors.nvim",
  },

  -- 💬 LSP UI 향상 (선택사항: 비활성화됨)
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    opts = {},
  },
}
