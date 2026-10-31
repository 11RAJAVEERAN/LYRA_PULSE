import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { shiftsApi } from '../api/shiftsApi'

export const shiftKeys = {
  all: ['shifts'],
  list: (params) => ['shifts', 'list', params],
  detail: (id) => ['shifts', 'detail', id],
  assignments: (params) => ['shift-assignments', 'list', params],
  history: (employeeId, params) => ['shift-assignments', 'history', employeeId, params],
  branches: ['shift-options', 'branches'],
  departments: ['shift-options', 'departments'],
  designations: ['shift-options', 'designations'],
  employees: (branch) => ['shift-options', 'employees', branch],
}

export function useShifts(params) {
  return useQuery({
    queryKey: shiftKeys.list(params),
    queryFn: ({ signal }) => shiftsApi.list(params, signal),
    placeholderData: keepPreviousData,
  })
}

export function useShift(id, enabled = true) {
  return useQuery({
    queryKey: shiftKeys.detail(id),
    queryFn: ({ signal }) => shiftsApi.get(id, signal),
    enabled: Boolean(id) && enabled,
  })
}

export function useShiftAssignments(params) {
  return useQuery({
    queryKey: shiftKeys.assignments(params),
    queryFn: ({ signal }) => shiftsApi.listAssignments(params, signal),
    placeholderData: keepPreviousData,
  })
}

export function useAssignmentHistory(employeeId, params, enabled = true) {
  return useQuery({
    queryKey: shiftKeys.history(employeeId, params),
    queryFn: ({ signal }) => shiftsApi.history(employeeId, params, signal),
    enabled: Boolean(employeeId) && enabled,
  })
}

export function useShiftOptions() {
  const branches = useQuery({ queryKey: shiftKeys.branches, queryFn: ({ signal }) => shiftsApi.branches(signal) })
  const departments = useQuery({ queryKey: shiftKeys.departments, queryFn: ({ signal }) => shiftsApi.departments(signal) })
  const designations = useQuery({ queryKey: shiftKeys.designations, queryFn: ({ signal }) => shiftsApi.designations(signal) })
  return { branches, departments, designations }
}

export function useEmployeesForBranch(branch) {
  return useQuery({
    queryKey: shiftKeys.employees(branch),
    queryFn: ({ signal }) => shiftsApi.employees(branch, signal),
    enabled: Boolean(branch),
  })
}

export function useCreateShift() {
  const client = useQueryClient()
  return useMutation({
    mutationFn: shiftsApi.create,
    onSuccess: () => {
      client.invalidateQueries({ queryKey: shiftKeys.all })
      client.invalidateQueries({ queryKey: ['shift-assignments'] })
    },
  })
}

export function useUpdateShift() {
  const client = useQueryClient()
  return useMutation({
    mutationFn: ({ id, payload }) => shiftsApi.update(id, payload),
    onSuccess: (_data, variables) => {
      client.invalidateQueries({ queryKey: shiftKeys.all })
      client.invalidateQueries({ queryKey: shiftKeys.detail(variables.id) })
      client.invalidateQueries({ queryKey: ['shift-assignments'] })
    },
  })
}

export function useAssignShift() {
  const client = useQueryClient()
  return useMutation({
    mutationFn: shiftsApi.assign,
    onSuccess: () => {
      client.invalidateQueries({ queryKey: ['shift-assignments'] })
      client.invalidateQueries({ queryKey: shiftKeys.all })
    },
  })
}

export function useBulkAssignShift() {
  const client = useQueryClient()
  return useMutation({
    mutationFn: shiftsApi.bulkAssign,
    onSuccess: () => {
      client.invalidateQueries({ queryKey: ['shift-assignments'] })
      client.invalidateQueries({ queryKey: shiftKeys.all })
    },
  })
}

