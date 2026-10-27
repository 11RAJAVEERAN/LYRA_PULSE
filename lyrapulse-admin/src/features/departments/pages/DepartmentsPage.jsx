import { OrganizationStructureManager } from '../../organizationStructure/components/OrganizationStructureManager'
import { departmentsApi } from '../api/departmentsApi'

const page = {
  key: 'departments',
  title: 'Departments',
  singular: 'Department',
  parentField: 'branch',
  parentLabel: 'Branch',
  secondColumn: 'Branch Name',
  secondValue: 'branch_name',
  parentValue: 'branch',
  employeeFilterParam: 'department',
  initialFilterFromSelectedBranch: true,
  lockParentWhenRelatedRecords: true,
  showBranchUnderParent: false,
}

const api = { ...departmentsApi, listParents: departmentsApi.listBranches }

export function DepartmentsPage() {
  return <OrganizationStructureManager page={page} api={api} />
}