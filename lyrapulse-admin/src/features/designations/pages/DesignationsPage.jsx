import { OrganizationStructureManager } from '../../organizationStructure/components/OrganizationStructureManager'
import { designationsApi } from '../api/designationsApi'

const page = {
  key: 'designations',
  title: 'Designations',
  singular: 'Designation',
  parentField: 'department',
  parentLabel: 'Department',
  secondColumn: 'Department Name',
  secondValue: 'department_name',
  parentValue: 'department',
  employeeFilterParam: 'designation',
  initialFilterFromSelectedBranch: false,
  lockParentWhenRelatedRecords: false,
  showBranchUnderParent: true,
}

const api = { ...designationsApi, listParents: designationsApi.listDepartments }

export function DesignationsPage() {
  return <OrganizationStructureManager page={page} api={api} />
}